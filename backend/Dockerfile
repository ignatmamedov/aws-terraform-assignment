# -------------------------------------------
# Stage 1: Build - Install Composer Dependencies
# -------------------------------------------
FROM composer:2 AS build

WORKDIR /app

# Copy composer files to leverage cache
COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-scripts --no-progress --no-interaction

# Copy the rest of the application code
COPY . /app

# Optimize the autoloader for production
RUN composer dump-autoload --optimize --no-dev --classmap-authoritative

# -------------------------------------------
# Stage 2: Production Image with Apache
# -------------------------------------------
FROM php:8.2-apache

# Install required extensions for PostgreSQL (and MySQL if needed)
RUN apt-get update && apt-get install -y \
    libpq-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache rewrite module required by Laravel
RUN a2enmod rewrite

# Copy the built application from the previous stage
COPY --from=build /app /var/www/html

# Ensure Apache serves the Laravel public directory
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf

# Adjust permissions for www-data (Apache user)
RUN chown -R www-data:www-data /var/www/html

# Expose port 80
EXPOSE 80

# Start Apache in the foreground
CMD ["apache2-foreground"]
