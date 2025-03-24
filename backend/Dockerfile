FROM composer:2
WORKDIR /backend

COPY . /backend
RUN composer install

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
