using UnityEngine;
using System.Collections.Generic;

public class AudioManager : MonoBehaviour
{
    private static AudioManager _instance;
    public static AudioManager Instance
    {
        get
        {
            if (_instance == null)
            {
                _instance = FindFirstObjectByType<AudioManager>();
                if (_instance == null)
                {
                    GameObject obj = new GameObject("AudioManager");
                    _instance = obj.AddComponent<AudioManager>();
                }
            }
            return _instance;
        }
    }

    [System.Serializable]
    public class Sound
    {
        public string name;
        public AudioClip clip;
        [Range(0f, 1f)]
        public float volume = 1f;
        [Range(0.1f, 3f)]
        public float pitch = 1f;
        public bool loop = false;

        [HideInInspector]
        public AudioSource source;
    }

    public Sound[] sounds;
    public Sound[] menuMusicTracks;
    public Sound[] gameMusicTracks;

    private Dictionary<string, Sound> soundDictionary = new Dictionary<string, Sound>();
    private AudioSource currentMusicSource;

    private void Awake()
    {
        if (_instance == null)
        {
            _instance = this;
        }
        else if (_instance != this)
        {
            Destroy(gameObject);
            return;
        }

        InitializeSounds();
    }

    private void OnDestroy()
    {
        if (_instance == this) _instance = null;
    }

    private void InitializeSounds()
    {
        soundDictionary.Clear();

        InitializeSoundArray(sounds);
        InitializeSoundArray(menuMusicTracks);
        InitializeSoundArray(gameMusicTracks);
    }

    private void InitializeSoundArray(Sound[] soundArray)
    {
        if (soundArray == null || soundArray.Length == 0)
        {
            return;
        }

        foreach (Sound s in soundArray)
        {
            if (string.IsNullOrEmpty(s.name) || s.clip == null)
            {
                Debug.LogWarning($"Sound {s.name} is not properly configured.");
                continue;
            }

            AudioSource source = gameObject.AddComponent<AudioSource>();
            s.source = source;
            source.clip = s.clip;
            source.volume = s.volume;
            source.pitch = s.pitch;
            source.loop = s.loop;

            soundDictionary[s.name] = s;
        }
    }

    public void Play(string name)
    {
        if (string.IsNullOrEmpty(name) || !soundDictionary.TryGetValue(name, out Sound s))
        {
            Debug.LogWarning($"Sound: {name} not found!");
            return;
        }

        s.source.Play();
    }

    public void Stop(string name)
    {
        if (string.IsNullOrEmpty(name) || !soundDictionary.TryGetValue(name, out Sound s))
        {
            Debug.LogWarning($"Sound: {name} not found!");
            return;
        }

        s.source.Stop();
    }

    public void PlayRandomMusic(Sound[] musicTracks)
    {
        if (musicTracks == null || musicTracks.Length == 0)
        {
            return;
        }

        if (currentMusicSource != null && currentMusicSource.isPlaying)
        {
            currentMusicSource.Stop();
        }

        Sound randomTrack = musicTracks[Random.Range(0, musicTracks.Length)];
        currentMusicSource = randomTrack.source;
        currentMusicSource.Play();
    }

    public void StopAllMusic()
    {
        if (currentMusicSource != null)
        {
            currentMusicSource.Stop();
        }
    }

    public void PauseMusic()
    {
        if (currentMusicSource != null)
        {
            currentMusicSource.Pause();
        }
    }

    public void ResumeMusic()
    {
        if (currentMusicSource != null)
        {
            currentMusicSource.UnPause();
        }
    }

    public void SetMusicVolume(float volume)
    {
        if (currentMusicSource != null)
        {
            currentMusicSource.volume = Mathf.Clamp01(volume);
        }
    }

    public AudioSource GetAudioSource(string name)
    {
        if (string.IsNullOrEmpty(name) || !soundDictionary.TryGetValue(name, out Sound s))
        {
            Debug.LogWarning($"Sound: {name} not found!");
            return null;
        }

        return s.source;
    }

    public void HandleGameStateChange(GameManager.GameState newState)
    {
        switch (newState)
        {
            case GameManager.GameState.MainMenu:
                PlayRandomMusic(menuMusicTracks);
                break;
            case GameManager.GameState.Playing:
                PlayRandomMusic(gameMusicTracks);
                break;
            case GameManager.GameState.Paused:
                PauseMusic();
                break;
            case GameManager.GameState.GameOver:
                Play(AudioEvents.GameOver);
                break;
        }
    }
}

public static class AudioEvents
{
    public const string StarCollected = "StarCollected";
    public const string PlayerShipEngine = "PlayerShipEngine";
    public const string EnemyShipPassby = "EnemyShipPassby";
    public const string Explosion = "Explosion";
    public const string GameOver = "GameOver";
    public const string NearMiss = "NearMiss";
}