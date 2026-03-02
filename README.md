# git-theme

**1 projet git = 1 couleur.** Terminal et VS Code, automatiquement.

Quand vous changez de repo, votre terminal et votre éditeur changent de palette. Chaque projet a sa propre identité visuelle — vous savez où vous êtes d'un coup d'œil.

![bash](https://img.shields.io/badge/bash-4.0+-black?logo=gnubash&logoColor=white)
![license](https://img.shields.io/badge/license-MIT-blue)

## Pourquoi

Quand on jongle entre plusieurs projets, tous les terminaux se ressemblent. On se trompe de fenêtre, on tape dans le mauvais repo.

**git-theme** règle ça : chaque repo obtient une palette de couleurs unique, cohérente entre le terminal et VS Code. Les palettes sont choisies pour être agréables à l'œil lors de longues sessions de code.

## Palettes incluses

| | | | |
|---|---|---|---|
| Catppuccin Mocha | Catppuccin Macchiato | Catppuccin Frappé | Rosé Pine |
| Rosé Pine Moon | Tokyo Night | Kanagawa | Gruvbox |
| Everforest | Nord | Dracula | Solarized |

Toutes les palettes sont dark, à faible fatigue visuelle.

## Installation

Ajoutez à votre `.bashrc` ou `.zshrc` :

```bash
source /chemin/vers/git-theme.sh
```

C'est tout. La prochaine fois que vous entrerez dans un repo git, une palette sera assignée automatiquement.

## Terminaux supportés

Konsole · Alacritty · Kitty · Ptyxis · foot · wezterm · tout terminal compatible OSC

## Commandes

```
git-theme ls         Voir les palettes disponibles
git-theme set <nom>  Choisir une palette pour le repo courant
git-theme current    Afficher la palette active
git-theme map        Voir toutes les associations repo → palette
git-theme reset      Retirer l'association du repo courant
git-theme preview    Prévisualiser toutes les palettes (3s chacune)
git-theme off        Désactiver et revenir aux couleurs par défaut
```

## Comment ça marche

1. Vous entrez dans un repo git
2. git-theme calcule un hash du nom/remote du repo
3. Une palette est assignée automatiquement (ou celle que vous avez choisie)
4. Le terminal et `.vscode/settings.json` sont mis à jour instantanément
5. Les associations sont stockées dans `~/.local/share/git-theme/map`

Le fichier `map` est un simple fichier texte — ajoutez-le à vos dotfiles pour synchroniser entre machines.
