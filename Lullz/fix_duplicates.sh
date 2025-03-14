#!/bin/bash

# This script renames duplicate files in the Lullz project to fix build conflicts

# Function to rename a file
rename_file() {
    local file=$1
    local new_name=$2
    
    echo "Renaming $file to $new_name"
    mv "$file" "$new_name"
}

# Project root directory
PROJECT_DIR="/Users/adam404/Library/Mobile Documents/com~apple~CloudDocs/Projects/lullz/Lullz"
cd "$PROJECT_DIR" || exit 1

# Rename duplicate AudioManager files
# The one in Audio/ seems to be the primary one based on imports
if [ -f "./Lullz/Core/Managers/AudioManager.swift" ]; then
    rename_file "./Lullz/Core/Managers/AudioManager.swift" "./Lullz/Core/Managers/LegacyAudioManager.swift"
fi

# Rename duplicate BinauralBeatsView files
if [ -f "./Lullz/Features/BinauralBeats/Views/BinauralBeatsView.swift" ]; then
    rename_file "./Lullz/Features/BinauralBeats/Views/BinauralBeatsView.swift" "./Lullz/Features/BinauralBeats/Views/BinauralBeatsViewFeature.swift"
fi

# Rename duplicate AudioControlsView files
if [ -f "./Lullz/UI/Components/AudioControlsView.swift" ]; then
    rename_file "./Lullz/UI/Components/AudioControlsView.swift" "./Lullz/UI/Components/AudioControlsUIView.swift"
fi

# Rename duplicate NoiseGeneratorView files
if [ -f "./Lullz/Features/SoundGeneration/Views/NoiseGeneratorView.swift" ]; then
    rename_file "./Lullz/Features/SoundGeneration/Views/NoiseGeneratorView.swift" "./Lullz/Features/SoundGeneration/Views/NoiseGeneratorFeatureView.swift"
fi

echo "Duplicate files have been renamed. Clean and rebuild your project in Xcode."
echo "You may need to update import references in files that used the renamed files." 