// ============================================
//  APHELION Gaming Hub - Application
// ============================================

(function() {
  'use strict';

  // --- Config (injected at build time) ---
  const CONFIG = __APHELION_CONFIG__;

  // --- State ---
  const state = {
    category: 'all',
    query: '',
    favoritesOnly: false,
    favorites: load('aphelion_fav', []),
    recent: load('aphelion_recent', [])
  };

  // --- DOM ---
  const $ = s => document.querySelector(s);
  const el = {
    grid: $('#grid'),
    search: $('#search'),
    filters: $('#filters'),
    title: $('#title'),
    count: $('#count'),
    favBtn: $('#fav-btn'),
    modal: $('#modal'),
    modalTitle: $('#modal-title'),
    modalClose: $('#modal-close'),
    frame: $('#frame'),
    modalExternal: $('#modal-external'),
    modalExternalLink: $('#modal-external-link'),
    toast: $('#toast'),
    statTotal: $('#stat-total'),
    statFav: $('#stat-fav'),
    statRecent: $('#stat-recent')
  };

  // --- Helpers ---
  function load(key, def) {
    try { return JSON.parse(localStorage.getItem(key)) || def; }
    catch { return def; }
  }

  function save(key, val) {
    localStorage.setItem(key, JSON.stringify(val));
  }

  function toast(msg) {
    el.toast.textContent = msg;
    el.toast.style.display = 'flex';
    setTimeout(() => el.toast.style.display = 'none', 2500);
  }

  // --- Filtering ---
  function getGames() {
    return CONFIG.games.filter(g => {
      const catOk = state.category === 'all' || g.category === state.category;
      const queryOk = g.title.toLowerCase().includes(state.query.toLowerCase());
      const favOk = !state.favoritesOnly || state.favorites.includes(g.id);
      return catOk && queryOk && favOk;
    });
  }

  // --- Rendering ---
  function render() {
    const games = getGames();

    // Stats
    el.statTotal.textContent = CONFIG.games.length;
    el.statFav.textContent = state.favorites.length;
    el.statRecent.textContent = state.recent.length;

    // Header
    const label = state.favoritesOnly ? 'Favorites' :
      state.category === 'all' ? 'All Games' :
      CONFIG.categories.find(c => c.id === state.category)?.label || state.category;
    el.title.textContent = label;
    el.count.textContent = `(${games.length})`;

    // Grid
    if (!games.length) {
      el.grid.innerHTML = `
        <div class="empty">
          <div class="empty-icon">🎮</div>
          <h3>${state.favoritesOnly ? 'No favorites yet' : 'No games found'}</h3>
          <p>${state.favoritesOnly ? 'Star games to add them here' : 'Try different filters'}</p>
        </div>`;
      return;
    }

    el.grid.innerHTML = games.map(g => {
      const isFav = state.favorites.includes(g.id);
      return `
        <article class="card" data-id="${g.id}">
          <div class="card-actions">
            <button class="card-btn ${isFav ? 'fav' : ''}" data-action="fav" data-id="${g.id}" title="${isFav ? 'Unfavorite' : 'Favorite'}">
              <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>
            </button>
            <button class="card-btn" data-action="open" data-id="${g.id}" title="New tab">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 13v6a2 2 0 01-2 2H5a2 2 0 01-2-2V8a2 2 0 012-2h6M15 3h6v6M10 14L21 3"/></svg>
            </button>
          </div>
          <img class="card-img" src="${g.thumb}" alt="${g.title}" loading="lazy" onerror="this.src='data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 300 140%22><rect fill=%22%2316161f%22 width=%22300%22 height=%22140%22/><text x=%22150%22 y=%2280%22 text-anchor=%22middle%22 fill=%22%236366f1%22 font-size=%2232%22>🎮</text></svg>'">
          <div class="card-body">
            <h3 class="card-title">${g.title}</h3>
            <span class="card-cat">${g.category}</span>
          </div>
        </article>`;
    }).join('');
  }

  // --- Modal ---
  function openGame(id) {
    const game = CONFIG.games.find(g => g.id === id);
    if (!game) return;

    el.modalTitle.textContent = game.title;
    if (game.proxy) {
      el.frame.style.display = '';
      el.modalExternal.style.display = 'none';
      el.frame.src = '/g/' + game.id + new URL(game.url).pathname;
    } else {
      el.frame.style.display = 'none';
      el.modalExternal.style.display = '';
      el.modalExternalLink.href = game.url;
    }
    el.modal.classList.add('open');
    document.body.style.overflow = 'hidden';

    // Track recent
    state.recent = [id, ...state.recent.filter(x => x !== id)].slice(0, 20);
    save('aphelion_recent', state.recent);
    render();
  }

  function closeModal() {
    el.modal.classList.remove('open');
    el.frame.src = '';
    el.frame.style.display = '';
    el.modalExternal.style.display = 'none';
    document.body.style.overflow = '';
  }

  // --- Actions ---
  function toggleFav(id) {
    const idx = state.favorites.indexOf(id);
    if (idx > -1) {
      state.favorites.splice(idx, 1);
      toast('Removed from favorites');
    } else {
      state.favorites.push(id);
      toast('Added to favorites');
    }
    save('aphelion_fav', state.favorites);
    render();
  }

  function openExternal(id) {
    const game = CONFIG.games.find(g => g.id === id);
    if (game) window.open(game.url, '_blank');
  }

  // --- Events ---
  el.search.addEventListener('input', e => {
    state.query = e.target.value;
    render();
  });

  el.filters.addEventListener('click', e => {
    const btn = e.target.closest('.filter');
    if (!btn) return;

    el.filters.querySelectorAll('.filter').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    state.category = btn.dataset.cat;
    state.favoritesOnly = false;
    el.favBtn.classList.remove('active');
    render();
  });

  el.favBtn.addEventListener('click', () => {
    state.favoritesOnly = !state.favoritesOnly;
    el.favBtn.classList.toggle('active');
    if (state.favoritesOnly) {
      el.filters.querySelectorAll('.filter').forEach(b => b.classList.remove('active'));
    } else {
      el.filters.querySelector('[data-cat="all"]').classList.add('active');
      state.category = 'all';
    }
    render();
  });

  el.grid.addEventListener('click', e => {
    const action = e.target.closest('[data-action]');
    const card = e.target.closest('.card');

    if (action) {
      e.stopPropagation();
      const id = action.dataset.id;
      if (action.dataset.action === 'fav') toggleFav(id);
      else if (action.dataset.action === 'open') openExternal(id);
    } else if (card) {
      openGame(card.dataset.id);
    }
  });

  el.modalClose.addEventListener('click', closeModal);
  el.modal.addEventListener('click', e => {
    if (e.target === el.modal) closeModal();
  });

  document.addEventListener('keydown', e => {
    if (e.ctrlKey && e.key === 'k') {
      e.preventDefault();
      el.search.focus();
    }
    if (e.key === 'Escape') closeModal();
    if (e.key === 'f' && el.modal.classList.contains('open')) {
      el.frame.requestFullscreen?.() || el.frame.webkitRequestFullscreen?.();
    }
  });

  // --- Init ---
  function init() {
    // Render filter buttons
    const filterHtml = `<button class="filter active" data-cat="all">All</button>` +
      CONFIG.categories.map(c => `<button class="filter" data-cat="${c.id}">${c.label}</button>`).join('');
    el.filters.innerHTML = filterHtml;

    render();
  }

  init();
})();
