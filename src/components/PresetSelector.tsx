import React from 'react';
import { breathingPresets } from '../data/meditationPresets';
import { MeditationPreset } from '../models/MeditationPreset';

interface PresetSelectorProps {
  onSelectPreset: (preset: MeditationPreset) => void;
}

const PresetSelector: React.FC<PresetSelectorProps> = ({ onSelectPreset }) => {
  return (
    <div className="preset-container">
      <h2>Breathing Technique Presets</h2>
      <div className="preset-grid">
        {breathingPresets.map(preset => (
          <div 
            key={preset.id} 
            className="preset-card"
            onClick={() => onSelectPreset(preset)}
          >
            <h3>{preset.name}</h3>
            <p>{preset.description}</p>
            <div className="preset-timing">
              <span>Inhale: {preset.inhaleSeconds}s</span>
              {preset.holdInhaleSeconds > 0 && <span>Hold: {preset.holdInhaleSeconds}s</span>}
              <span>Exhale: {preset.exhaleSeconds}s</span>
              {preset.holdExhaleSeconds > 0 && <span>Hold: {preset.holdExhaleSeconds}s</span>}
            </div>
            <div className="preset-rounds">
              {preset.rounds > 0 ? `${preset.rounds} rounds` : 'Continuous'}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default PresetSelector;
