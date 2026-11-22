const fs = require('fs');
const path = require('path');

const audioDir = 'C:/Users/User/.gemini/antigravity/scratch/neon-vanguards/assets/audio';
if (!fs.existsSync(audioDir)) {
    fs.mkdirSync(audioDir, { recursive: true });
}

function createWavBuffer(samples, sampleRate = 22050) {
    const numSamples = samples.length;
    const bitsPerSample = 16;
    const numChannels = 1;
    const byteRate = sampleRate * numChannels * (bitsPerSample / 8);
    const blockAlign = numChannels * (bitsPerSample / 8);
    const dataSize = numSamples * (bitsPerSample / 8);
    const header = Buffer.alloc(44);

    header.write('RIFF', 0);
    header.writeUInt32LE(36 + dataSize, 4);
    header.write('WAVE', 8);
    header.write('fmt ', 12);
    header.writeUInt32LE(16, 16);
    header.writeUInt16LE(1, 20); // PCM
    header.writeUInt16LE(numChannels, 22);
    header.writeUInt32LE(sampleRate, 24);
    header.writeUInt32LE(byteRate, 28);
    header.writeUInt16LE(blockAlign, 32);
    header.writeUInt16LE(bitsPerSample, 34);
    header.write('data', 36);
    header.writeUInt32LE(dataSize, 40);

    const pcm = Buffer.alloc(dataSize);
    for (let i = 0; i < numSamples; i++) {
        let s = Math.max(-1.0, Math.min(1.0, samples[i]));
        const val = s < 0 ? s * 32768 : s * 32767;
        pcm.writeInt16LE(Math.round(val), i * 2);
    }

    return Buffer.concat([header, pcm]);
}

// ------------------- 1. Plasma Carbine (Rifle) -------------------
// Fast energetic plasma pew-pew with resonant laser decay
function genRifle() {
    const sr = 22050;
    const dur = 0.16;
    const len = Math.floor(sr * dur);
    const samples = new Float32Array(len);

    for (let i = 0; i < len; i++) {
        const t = i / sr;
        const progress = i / len;
        // Pitch drop from 1400 Hz to 180 Hz
        const freq = 1400 * Math.exp(-progress * 5.0) + 120;
        const phase = t * freq * 2 * Math.PI;
        // Laser tone (square + sine mix)
        let wave = Math.sin(phase) * 0.6 + (Math.sin(phase) > 0 ? 0.3 : -0.3);
        // Noise punch at start
        const noise = (Math.random() * 2 - 1) * Math.exp(-progress * 25.0) * 0.4;
        const env = Math.exp(-progress * 6.0);
        samples[i] = (wave + noise) * env * 0.85;
    }
    return createWavBuffer(samples, sr);
}

// ------------------- 2. Scatter Shotgun -------------------
// Heavy blast with low punch and wide spreading plasma noise
function genShotgun() {
    const sr = 22050;
    const dur = 0.38;
    const len = Math.floor(sr * dur);
    const samples = new Float32Array(len);

    for (let i = 0; i < len; i++) {
        const t = i / sr;
        const progress = i / len;
        // Heavy bass thud
        const bassFreq = 160 * Math.exp(-progress * 8.0) + 40;
        const bass = Math.sin(t * bassFreq * 2 * Math.PI) * Math.exp(-progress * 5.0) * 0.8;
        // Crunch noise
        const noise = (Math.random() * 2 - 1) * Math.exp(-progress * 7.0) * 0.7;
        // Mid sizzle
        const midFreq = 600 * Math.exp(-progress * 4.0);
        const mid = Math.sin(t * midFreq * 2 * Math.PI) * Math.exp(-progress * 10.0) * 0.3;

        samples[i] = (bass + noise + mid) * 0.75;
    }
    return createWavBuffer(samples, sr);
}

// ------------------- 3. Laser Railgun (Sniper) -------------------
// Piercing high-voltage beam with sharp harmonic ringing
function genSniper() {
    const sr = 22050;
    const dur = 0.42;
    const len = Math.floor(sr * dur);
    const samples = new Float32Array(len);

    for (let i = 0; i < len; i++) {
        const t = i / sr;
        const progress = i / len;
        // High piercing frequency
        const freq = 2600 * Math.exp(-progress * 3.5) + 300;
        // FM modulation for electric laser texture
        const mod = Math.sin(t * 880 * 2 * Math.PI) * 400;
        const beam = Math.sin(t * (freq + mod) * 2 * Math.PI) * 0.7;
        const sub = Math.sin(t * (freq * 0.5) * 2 * Math.PI) * 0.3;
        const crack = (Math.random() * 2 - 1) * Math.exp(-progress * 35.0) * 0.6;
        const env = Math.exp(-progress * 4.5);
        samples[i] = (beam + sub + crack) * env * 0.8;
    }
    return createWavBuffer(samples, sr);
}

// ------------------- 4. Rocket Launcher -------------------
// Deep ignition whoosh + concussive fire
function genRocket() {
    const sr = 22050;
    const dur = 0.48;
    const len = Math.floor(sr * dur);
    const samples = new Float32Array(len);

    for (let i = 0; i < len; i++) {
        const t = i / sr;
        const progress = i / len;
        // Ignition thump
        const thumpFreq = 120 * Math.exp(-progress * 12.0) + 35;
        const thump = Math.sin(t * thumpFreq * 2 * Math.PI) * Math.exp(-progress * 8.0) * 0.9;
        // Exhaust rocket whoosh
        const whoosh = (Math.random() * 2 - 1) * Math.sin(progress * Math.PI) * 0.6;
        const sub = Math.sin(t * 70 * 2 * Math.PI) * (1.0 - progress) * 0.4;
        samples[i] = (thump + whoosh + sub) * 0.8;
    }
    return createWavBuffer(samples, sr);
}

// ------------------- 5. Explosion -------------------
// Heavy explosive detonation
function genExplosion() {
    const sr = 22050;
    const dur = 0.65;
    const len = Math.floor(sr * dur);
    const samples = new Float32Array(len);

    for (let i = 0; i < len; i++) {
        const t = i / sr;
        const progress = i / len;
        const bass = Math.sin(t * (90 * Math.exp(-progress * 4.0) + 30) * 2 * Math.PI) * Math.exp(-progress * 3.0) * 0.7;
        const rumble = (Math.random() * 2 - 1) * Math.exp(-progress * 2.5) * 0.7;
        samples[i] = (bass + rumble) * 0.85;
    }
    return createWavBuffer(samples, sr);
}

// ------------------- 6. Health Pickup Chime -------------------
// Uplifting 3-note cyber chime
function genPickup() {
    const sr = 22050;
    const dur = 0.32;
    const len = Math.floor(sr * dur);
    const samples = new Float32Array(len);
    const notes = [523.25, 659.25, 783.99, 1046.5]; // C5, E5, G5, C6

    for (let i = 0; i < len; i++) {
        const t = i / sr;
        const nIdx = Math.min(notes.length - 1, Math.floor(t / (dur / notes.length)));
        const freq = notes[nIdx];
        const noteT = (i % Math.floor(len / notes.length)) / (len / notes.length);
        const env = Math.exp(-noteT * 3.0);
        const wave = Math.sin(t * freq * 2 * Math.PI) * 0.6 + Math.sin(t * freq * 2 * 2 * Math.PI) * 0.2;
        samples[i] = wave * env * 0.7;
    }
    return createWavBuffer(samples, sr);
}

// ------------------- 7. Hurt / Impact -------------------
function genHurt() {
    const sr = 22050;
    const dur = 0.2;
    const len = Math.floor(sr * dur);
    const samples = new Float32Array(len);

    for (let i = 0; i < len; i++) {
        const t = i / sr;
        const progress = i / len;
        const freq = 220 * Math.exp(-progress * 8.0) + 50;
        const wave = Math.sin(t * freq * 2 * Math.PI) * 0.6;
        const crunch = (Math.random() * 2 - 1) * Math.exp(-progress * 10.0) * 0.5;
        samples[i] = (wave + crunch) * Math.exp(-progress * 5.0) * 0.8;
    }
    return createWavBuffer(samples, sr);
}

// ------------------- 8. Reload Click -------------------
function genReload() {
    const sr = 22050;
    const dur = 0.25;
    const len = Math.floor(sr * dur);
    const samples = new Float32Array(len);

    for (let i = 0; i < len; i++) {
        const t = i / sr;
        // Two distinct mechanical clicks at 0.04s and 0.16s
        let click = 0;
        if (t >= 0.02 && t < 0.08) {
            const dt = (t - 0.02) / 0.06;
            click += Math.sin((t - 0.02) * 1800 * 2 * Math.PI) * Math.exp(-dt * 15.0) * 0.8;
        }
        if (t >= 0.14 && t < 0.22) {
            const dt = (t - 0.14) / 0.08;
            click += Math.sin((t - 0.14) * 2200 * 2 * Math.PI) * Math.exp(-dt * 12.0) * 0.9;
        }
        samples[i] = click * 0.7;
    }
    return createWavBuffer(samples, sr);
}

// ------------------- 9. Cyberpunk BGM Loop -------------------
// 120 BPM Synthwave / Chiptune battle groove (8.0 seconds seamless loop, 16 beats)
function genBGM() {
    const sr = 22050;
    const bpm = 124;
    const beatDur = 60 / bpm; // ~0.48387s
    const totalBeats = 16;
    const dur = beatDur * totalBeats; // ~7.7419s
    const len = Math.floor(sr * dur);
    const samples = new Float32Array(len);

    // Bassline chord progression in D Minor: D -> F -> C -> G (4 beats each)
    const rootNotes = [73.42, 87.31, 65.41, 98.00]; // D2, F2, C2, G2
    // Lead arpeggio notes in D minor pentatonic: D4, F4, G4, A4, C5
    const leadNotes = [293.66, 349.23, 392.00, 440.00, 523.25, 587.33];

    for (let i = 0; i < len; i++) {
        const t = (i / len) * dur;
        const beatNum = t / beatDur;
        const beatFraction = beatNum % 1.0;
        const barNum = Math.floor(beatNum / 4);
        const root = rootNotes[barNum % 4];

        // 1. Kick Drum (on every beat 0, 1, 2, 3)
        let kick = 0;
        if (beatFraction < 0.22) {
            const kt = beatFraction * beatDur;
            const kFreq = 140 * Math.exp(-kt * 22.0) + 42;
            kick = Math.sin(kt * kFreq * 2 * Math.PI) * Math.exp(-kt * 18.0) * 0.75;
        }

        // 2. Snare / Clap (on beats 1 and 3 of every 4-beat bar)
        let snare = 0;
        const isSnareBeat = (Math.floor(beatNum) % 2 === 1);
        if (isSnareBeat && beatFraction < 0.25) {
            const st = beatFraction * beatDur;
            const noise = (Math.random() * 2 - 1) * Math.exp(-st * 16.0) * 0.45;
            const body = Math.sin(st * 180 * 2 * Math.PI) * Math.exp(-st * 24.0) * 0.35;
            snare = (noise + body);
        }

        // 3. Hi-Hat (on every 8th note, i.e. fraction 0.0 and 0.5)
        let hihat = 0;
        const subFraction = (beatNum * 2) % 1.0;
        if (subFraction < 0.08) {
            const ht = subFraction * (beatDur / 2);
            hihat = (Math.random() * 2 - 1) * Math.exp(-ht * 50.0) * 0.18;
        }

        // 4. Bassline (16th-note driving synth bass)
        const sixteenth = (beatNum * 4) % 1.0;
        const sT = sixteenth * (beatDur / 4);
        const bassEnv = Math.exp(-sT * 10.0);
        // Play octave jump on 16th notes: root, root*1.5, root*2, etc.
        const sIdx = Math.floor((beatNum * 4) % 4);
        const bassPitch = (sIdx === 2 || sIdx === 3) ? root * 2.0 : root;
        const bassWave = (Math.sin(t * bassPitch * 2 * Math.PI) * 0.5 + Math.sin(t * (bassPitch * 2) * 2 * Math.PI) * 0.25) * bassEnv;

        // 5. Synth Lead Arpeggio (8th note pattern)
        const arpStep = Math.floor(beatNum * 2) % leadNotes.length;
        const leadPitch = leadNotes[arpStep];
        const arpFraction = (beatNum * 2) % 1.0;
        const arpEnv = Math.exp(-arpFraction * 4.0);
        // Resonant cyber synth wave
        const leadWave = (Math.sin(t * leadPitch * 2 * Math.PI) * 0.35 + (Math.sin(t * leadPitch * 2 * Math.PI) > 0 ? 0.15 : -0.15)) * arpEnv;

        // Combine mix
        const mix = (kick * 0.6) + (snare * 0.5) + (hihat * 0.4) + (bassWave * 0.45) + (leadWave * 0.35);
        samples[i] = mix * 0.7;
    }

    // Apply brief 20ms crossfade at loop boundary to prevent any click
    const fadeSamples = Math.floor(sr * 0.02);
    for (let i = 0; i < fadeSamples; i++) {
        const factor = i / fadeSamples;
        samples[i] = samples[i] * factor + samples[len - 1 - (fadeSamples - 1 - i)] * (1 - factor);
    }

    return createWavBuffer(samples, sr);
}

// Write files
fs.writeFileSync(path.join(audioDir, 'gun_rifle.wav'), genRifle());
fs.writeFileSync(path.join(audioDir, 'gun_shotgun.wav'), genShotgun());
fs.writeFileSync(path.join(audioDir, 'gun_sniper.wav'), genSniper());
fs.writeFileSync(path.join(audioDir, 'gun_rocket.wav'), genRocket());
fs.writeFileSync(path.join(audioDir, 'explosion.wav'), genExplosion());
fs.writeFileSync(path.join(audioDir, 'pickup.wav'), genPickup());
fs.writeFileSync(path.join(audioDir, 'hurt.wav'), genHurt());
fs.writeFileSync(path.join(audioDir, 'reload.wav'), genReload());
fs.writeFileSync(path.join(audioDir, 'bgm_battle.wav'), genBGM());

console.log('All 9 audio files generated successfully in assets/audio!');
