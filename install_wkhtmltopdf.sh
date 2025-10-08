#!/bin/bash

echo "=== Installation de wkhtmltopdf ==="
echo ""

# Détecter l'OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 Système détecté: Linux"
    
    # Ubuntu/Debian
    if command -v apt-get &> /dev/null; then
        echo "📦 Installation via apt-get..."
        sudo apt-get update
        sudo apt-get install -y wkhtmltopdf
        
    # CentOS/RHEL/Fedora
    elif command -v yum &> /dev/null; then
        echo "📦 Installation via yum..."
        sudo yum install -y wkhtmltopdf
        
    elif command -v dnf &> /dev/null; then
        echo "📦 Installation via dnf..."
        sudo dnf install -y wkhtmltopdf
        
    else
        echo "❌ Gestionnaire de paquets non supporté"
        echo "💡 Téléchargez manuellement depuis: https://wkhtmltopdf.org/downloads.html"
        exit 1
    fi
    
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Système détecté: macOS"
    
    # Homebrew
    if command -v brew &> /dev/null; then
        echo "📦 Installation via Homebrew..."
        brew install wkhtmltopdf
        
    else
        echo "❌ Homebrew non installé"
        echo "💡 Installez Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        echo "💡 Ou téléchargez manuellement: https://wkhtmltopdf.org/downloads.html"
        exit 1
    fi
    
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    echo "🪟 Système détecté: Windows"
    echo "💡 Téléchargez l'installateur depuis: https://wkhtmltopdf.org/downloads.html"
    echo "💡 Ou utilisez Chocolatey: choco install wkhtmltopdf"
    exit 1
    
else
    echo "❓ Système non reconnu: $OSTYPE"
    echo "💡 Téléchargez manuellement depuis: https://wkhtmltopdf.org/downloads.html"
    exit 1
fi

echo ""
echo "=== Vérification de l'installation ==="

if command -v wkhtmltopdf &> /dev/null; then
    echo "✅ wkhtmltopdf installé avec succès!"
    echo "📍 Chemin: $(which wkhtmltopdf)"
    echo "📋 Version: $(wkhtmltopdf --version)"
    
    echo ""
    echo "=== Test de génération PDF ==="
    
    # Créer un fichier HTML de test
    cat > /tmp/test.html << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Test PDF</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
    </style>
</head>
<body>
    <h1>Test de génération PDF</h1>
    <p>Ce fichier a été généré par wkhtmltopdf.</p>
    <p>Date: $(date)</p>
</body>
</html>
EOF
    
    # Générer le PDF de test
    if wkhtmltopdf /tmp/test.html /tmp/test.pdf 2>/dev/null; then
        echo "✅ Test de génération PDF réussi!"
        echo "📄 Fichier généré: /tmp/test.pdf"
        echo "📊 Taille: $(ls -lh /tmp/test.pdf | awk '{print $5}')"
        
        # Nettoyer les fichiers de test
        rm -f /tmp/test.html /tmp/test.pdf
        
    else
        echo "❌ Échec du test de génération PDF"
        echo "🔍 Vérifiez les permissions et les dépendances"
    fi
    
else
    echo "❌ wkhtmltopdf n'est pas installé ou non accessible"
    echo "🔍 Vérifiez votre PATH ou réessayez l'installation"
    exit 1
fi

echo ""
echo "🎉 Installation terminée!"
echo "💡 Vous pouvez maintenant exécuter: php fix_corrupted_pdfs.php"
