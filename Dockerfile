FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY proxy-common.conf /etc/nginx/proxy-common.conf
COPY locations.d/ /etc/nginx/locations.d/
COPY dist/index.html /usr/share/nginx/html/index.html
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
