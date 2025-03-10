import { MeditationPreset } from '../models/MeditationPreset';

export const breathingPresets: MeditationPreset[] = [
  {
    id: 'box-breathing',
    name: 'Box Breathing',
    description: 'Equal inhale, hold, exhale, and hold. Great for stress reduction and focus.',
    technique: 'box',
    inhaleSeconds: 4,
    holdInhaleSeconds: 4,
    exhaleSeconds: 4,
    holdExhaleSeconds: 4,
    rounds: 10
  },
  {
    id: '4-7-8-breathing',
    name: '4-7-8 Breathing',
    description: 'Inhale for 4, hold for 7, exhale for 8. Helps with anxiety and sleep.',
    technique: '4-7-8',
    inhaleSeconds: 4,
    holdInhaleSeconds: 7,
    exhaleSeconds: 8,
    holdExhaleSeconds: 0,
    rounds: 5
  },
  {
    id: 'diaphragmatic',
    name: 'Diaphragmatic Breathing',
    description: 'Deep belly breathing for relaxation and improved oxygen exchange.',
    technique: 'diaphragmatic',
    inhaleSeconds: 4,
    holdInhaleSeconds: 0,
    exhaleSeconds: 6,
    holdExhaleSeconds: 0,
    rounds: 10
  },
  {
    id: 'wim-hof',
    name: 'Wim Hof Method',
    description: 'Powerful deep breathing followed by breath retention. Improves energy and immunity.',
    technique: 'wim-hof',
    inhaleSeconds: 2,
    holdInhaleSeconds: 0,
    exhaleSeconds: 2,
    holdExhaleSeconds: 0,
    rounds: 30
  },
  {
    id: 'alternate-nostril',
    name: 'Alternate Nostril Breathing',
    description: 'Balances the nervous system and promotes calm focus.',
    technique: 'alternate-nostril',
    inhaleSeconds: 4,
    holdInhaleSeconds: 2,
    exhaleSeconds: 4,
    holdExhaleSeconds: 0,
    rounds: 10
  },
  {
    id: 'resonant-breathing',
    name: 'Resonant Breathing (5.5 Breathing)',
    description: 'Inhale and exhale for 5.5 seconds each. Optimizes heart rate variability.',
    technique: 'custom',
    inhaleSeconds: 5.5,
    holdInhaleSeconds: 0,
    exhaleSeconds: 5.5,
    holdExhaleSeconds: 0,
    rounds: 10
  },
  {
    id: 'ujjayi-breathing',
    name: 'Ujjayi Breathing',
    description: 'Ocean-sounding breath used in yoga for focus and concentration.',
    technique: 'custom',
    inhaleSeconds: 5,
    holdInhaleSeconds: 0,
    exhaleSeconds: 5,
    holdExhaleSeconds: 0,
    rounds: 12
  },
  {
    id: 'bhramari-breathing',
    name: 'Bhramari (Bee Breath)',
    description: 'Humming exhalation for anxiety and mental tension release.',
    technique: 'custom',
    inhaleSeconds: 4,
    holdInhaleSeconds: 0,
    exhaleSeconds: 6,
    holdExhaleSeconds: 0,
    rounds: 7
  },
  {
    id: 'breathing-meditation',
    name: 'Mindful Breathing',
    description: 'Simple awareness of breath to cultivate mindfulness.',
    technique: 'custom',
    inhaleSeconds: 0, // Natural pace
    holdInhaleSeconds: 0,
    exhaleSeconds: 0, // Natural pace
    holdExhaleSeconds: 0,
    rounds: 0, // Timed rather than counted
  },
  {
    id: 'coherent-breathing',
    name: 'Coherent Breathing',
    description: 'Five breaths per minute for autonomic nervous system balance.',
    technique: 'custom',
    inhaleSeconds: 6,
    holdInhaleSeconds: 0,
    exhaleSeconds: 6,
    holdExhaleSeconds: 0,
    rounds: 20
  }
];
