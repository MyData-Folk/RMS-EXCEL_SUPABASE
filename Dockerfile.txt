# Dockerfile pour Supabase Auto-Importer (RMS Sync)
# Application Flask avec Python 3.12

# Image de base
FROM python:3.12-slim

# Métadonnées
LABEL maintainer="RMS Sync"
LABEL description="Supabase Auto-Importer - Application ETL pour importer des fichiers Excel/CSV vers Supabase"
LABEL version="2.0"

# Arguments de construction
ARG FLASK_ENV=production

# Variables d'environnement
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV FLASK_ENV=${FLASK_ENV}

# Mise à jour et installation des dépendances système
RUN apt-get update && apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Répertoire de travail
WORKDIR /app

# Copie des fichiers de configuration
COPY requirements.txt .
COPY setup_db.sql .

# Installation des dépendances Python
RUN pip install --no-cache-dir -r requirements.txt

# Copie du code de l'application
COPY app.py .
COPY index.html .

# Création du dossier uploads
RUN mkdir -p uploads && chmod 777 uploads

# Exposition du port
EXPOSE 5000

# Commande de démarrage
CMD ["python", "app.py"]
