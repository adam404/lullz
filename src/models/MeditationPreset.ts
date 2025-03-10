export interface MeditationPreset {
  id: string;
  name: string;
  description: string;
  technique: 'box' | 'diaphragmatic' | 'alternate-nostril' | '4-7-8' | 'wim-hof' | 'custom';
  inhaleSeconds: number;
  holdInhaleSeconds: number;
  exhaleSeconds: number;
  holdExhaleSeconds: number;
  rounds: number;
  guidanceAudio?: string;
  backgroundSound?: string;
}
