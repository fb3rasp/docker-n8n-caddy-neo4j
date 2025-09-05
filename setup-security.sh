#!/bin/bash
set -e

echo "🔐 Setting up secure n8n + Neo4j environment..."

# Create secrets directory
mkdir -p secrets

# Generate secure Neo4j password if not exists
if [ ! -f secrets/neo4j_password.txt ]; then
    echo "🔑 Generating secure Neo4j password..."
    openssl rand -base64 32 > secrets/neo4j_password.txt
    echo "✅ Neo4j password generated and saved to secrets/neo4j_password.txt"
else
    echo "✅ Neo4j password already exists"
fi

# Set proper permissions on secrets
chmod 600 secrets/neo4j_password.txt
chmod 700 secrets/

# Create .env template if not exists
if [ ! -f .env ]; then
    echo "📝 Creating .env template..."
    cat > .env << EOF
# Project configuration
DATA_FOLDER=$(pwd)
SUBDOMAIN=n8n
DOMAIN_NAME=local.dev
GENERIC_TIMEZONE=Pacific/Auckland

# Neo4j credentials are managed via Docker secrets
# Password is stored in secrets/neo4j_password.txt
NEO4J_USERNAME=neo4j
EOF
    echo "✅ .env template created - please review and customize"
else
    echo "✅ .env file already exists"
fi

# Add secrets to .gitignore
if [ ! -f .gitignore ]; then
    echo "secrets/" > .gitignore
    echo ".env" >> .gitignore
    echo "✅ .gitignore created"
else
    if ! grep -q "secrets/" .gitignore; then
        echo "secrets/" >> .gitignore
        echo "✅ Added secrets/ to .gitignore"
    fi
    if ! grep -q ".env" .gitignore; then
        echo ".env" >> .gitignore
        echo "✅ Added .env to .gitignore"
    fi
fi

echo ""
echo "🛡️  Security setup complete!"
echo "📋 Next steps:"
echo "   1. Review the generated password in secrets/neo4j_password.txt"
echo "   2. Customize .env file if needed"
echo "   3. Run: docker-compose up -d"
echo ""
echo "🔐 Security features enabled:"
echo "   ✅ Docker secrets for passwords"
echo "   ✅ Isolated Docker network"
echo "   ✅ Localhost-only Neo4j access"
echo "   ✅ Resource limits on all containers"
echo "   ✅ No-new-privileges security option"
echo "   ✅ Specific image versions (no :latest)"
echo ""
