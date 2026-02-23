using UnityEngine;
using Unity.Services.LevelPlay;

public class AdManager : MonoBehaviour
{
    public static AdManager Instance { get; private set; }

    [SerializeField] private string _appKey;
    [SerializeField] private string _bannerAdUnitId = "Banner_Android";
    [SerializeField] private string _interstitialAdUnitId = "Interstitial_Android";

    private LevelPlayBannerAd _bannerAd;
    private LevelPlayInterstitialAd _interstitialAd;

    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
        }
        else
        {
            Destroy(gameObject);
        }
    }

    private void Start()
    {
        LevelPlay.OnInitSuccess += OnInitSuccess;
        LevelPlay.OnInitFailed += OnInitFailed;
        LevelPlay.Init(_appKey);
    }

    private void OnInitSuccess(LevelPlayConfiguration configuration)
    {
        Debug.Log("LevelPlay initialization complete.");
        CreateBannerAd();
        CreateInterstitialAd();
        LoadBannerAd();
        LoadInterstitialAd();
    }

    private void OnInitFailed(LevelPlayInitError error)
    {
        Debug.Log($"LevelPlay initialization failed: {error}");
    }

    #region Banner Ad Methods
    private void CreateBannerAd()
    {
        var config = new LevelPlayBannerAd.Config.Builder()
            .SetSize(LevelPlayAdSize.BANNER)
            .SetPosition(LevelPlayBannerPosition.BottomCenter)
            .SetDisplayOnLoad(true)
            .SetRespectSafeArea(true)
            .Build();

        _bannerAd = new LevelPlayBannerAd(_bannerAdUnitId, config);

        _bannerAd.OnAdLoaded += BannerOnAdLoaded;
        _bannerAd.OnAdLoadFailed += BannerOnAdLoadFailed;
        _bannerAd.OnAdDisplayed += BannerOnAdDisplayed;
        _bannerAd.OnAdDisplayFailed += BannerOnAdDisplayFailed;
        _bannerAd.OnAdClicked += BannerOnAdClicked;
        _bannerAd.OnAdCollapsed += BannerOnAdCollapsed;
        _bannerAd.OnAdExpanded += BannerOnAdExpanded;
        _bannerAd.OnAdLeftApplication += BannerOnAdLeftApplication;
    }

    public void LoadBannerAd()
    {
        _bannerAd?.LoadAd();
    }

    public void ShowBannerAd()
    {
        _bannerAd?.ShowAd();
    }

    public void HideBannerAd()
    {
        _bannerAd?.HideAd();
    }

    public void DestroyBannerAd()
    {
        _bannerAd?.DestroyAd();
    }

    private void BannerOnAdLoaded(LevelPlayAdInfo adInfo)
    {
        Debug.Log("Banner ad loaded");
    }

    private void BannerOnAdLoadFailed(LevelPlayAdError error)
    {
        Debug.Log($"Banner ad load failed: {error}");
    }

    private void BannerOnAdDisplayed(LevelPlayAdInfo adInfo) { }
    private void BannerOnAdDisplayFailed(LevelPlayAdInfo adInfo, LevelPlayAdError error)
    {
        Debug.Log($"Banner ad display failed: {error}");
    }
    private void BannerOnAdClicked(LevelPlayAdInfo adInfo) { }
    private void BannerOnAdCollapsed(LevelPlayAdInfo adInfo) { }
    private void BannerOnAdExpanded(LevelPlayAdInfo adInfo) { }
    private void BannerOnAdLeftApplication(LevelPlayAdInfo adInfo) { }
    #endregion

    #region Interstitial Ad Methods
    private void CreateInterstitialAd()
    {
        _interstitialAd = new LevelPlayInterstitialAd(_interstitialAdUnitId);

        _interstitialAd.OnAdLoaded += InterstitialOnAdLoaded;
        _interstitialAd.OnAdLoadFailed += InterstitialOnAdLoadFailed;
        _interstitialAd.OnAdDisplayed += InterstitialOnAdDisplayed;
        _interstitialAd.OnAdDisplayFailed += InterstitialOnAdDisplayFailed;
        _interstitialAd.OnAdClicked += InterstitialOnAdClicked;
        _interstitialAd.OnAdClosed += InterstitialOnAdClosed;
        _interstitialAd.OnAdInfoChanged += InterstitialOnAdInfoChanged;
    }

    public void LoadInterstitialAd()
    {
        Debug.Log("Loading interstitial ad: " + _interstitialAdUnitId);
        _interstitialAd?.LoadAd();
    }

    public void ShowInterstitialAd()
    {
        if (_interstitialAd != null && _interstitialAd.IsAdReady())
        {
            Debug.Log("Showing interstitial ad: " + _interstitialAdUnitId);
            _interstitialAd.ShowAd();
        }
        else
        {
            Debug.Log("Interstitial ad not ready. Loading...");
            LoadInterstitialAd();
        }
    }

    private void InterstitialOnAdLoaded(LevelPlayAdInfo adInfo)
    {
        Debug.Log("Interstitial ad loaded");
    }

    private void InterstitialOnAdLoadFailed(LevelPlayAdError error)
    {
        Debug.Log($"Interstitial ad load failed: {error}");
    }

    private void InterstitialOnAdDisplayed(LevelPlayAdInfo adInfo)
    {
        Debug.Log("Interstitial ad displayed");
    }

    private void InterstitialOnAdDisplayFailed(LevelPlayAdInfo adInfo, LevelPlayAdError error)
    {
        Debug.Log($"Interstitial ad display failed: {error}");
    }

    private void InterstitialOnAdClicked(LevelPlayAdInfo adInfo) { }

    private void InterstitialOnAdClosed(LevelPlayAdInfo adInfo)
    {
        Debug.Log("Interstitial ad closed");
        LoadInterstitialAd();
    }

    private void InterstitialOnAdInfoChanged(LevelPlayAdInfo adInfo) { }
    #endregion

    private void OnDestroy()
    {
        LevelPlay.OnInitSuccess -= OnInitSuccess;
        LevelPlay.OnInitFailed -= OnInitFailed;

        _bannerAd?.DestroyAd();
        _interstitialAd?.DestroyAd();
    }
}