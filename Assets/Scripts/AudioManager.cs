using System;
using UnityEngine;

/// <summary>
/// Quản lý âm thanh toàn bộ trò chơi: Nhạc nền (BGM) chiến trận hào hùng
/// và hệ thống hiệu ứng âm thanh (SFX) được tổng hợp procedural PCM chất lượng cao.
/// </summary>
public class AudioManager : MonoBehaviour
{
    private static AudioManager _instance;
    public static AudioManager Instance
    {
        get
        {
            if (_instance == null)
            {
                var go = new GameObject("AudioManager");
                DontDestroyOnLoad(go);
                _instance = go.AddComponent<AudioManager>();
            }
            return _instance;
        }
    }

    private AudioSource bgmSource;
    private AudioSource sfxSource;
    private AudioSource voiceSource;
    private System.Collections.Generic.Dictionary<string, AudioClip> voiceClipCache = new System.Collections.Generic.Dictionary<string, AudioClip>(StringComparer.OrdinalIgnoreCase);

    private AudioClip bgmClip;
    private AudioClip slashClip;
    private AudioClip damageClip;
    private AudioClip parryClip;
    private AudioClip skillClip;
    private AudioClip cardDrawClip;
    private AudioClip cardSelectClip;
    private AudioClip cardDiscardClip;
    private AudioClip healClip;
    private AudioClip victoryClip;

    private void Awake()
    {
        if (_instance != null && _instance != this)
        {
            Destroy(gameObject);
            return;
        }
        _instance = this;
        DontDestroyOnLoad(gameObject);

        bgmSource = gameObject.AddComponent<AudioSource>();
        bgmSource.loop = true;
        bgmSource.volume = 0.35f;

        sfxSource = gameObject.AddComponent<AudioSource>();
        sfxSource.volume = 0.85f;

        voiceSource = gameObject.AddComponent<AudioSource>();
        voiceSource.volume = 1.0f;

        GenerateClips();
    }

    private void Start()
    {
        PlayBGM();
    }

    private void GenerateClips()
    {
        slashClip = CreateSlashClip();
        damageClip = CreateDamageClip();
        parryClip = CreateParryClip();
        skillClip = CreateSkillClip();
        cardDrawClip = CreateCardDrawClip();
        cardSelectClip = CreateCardSelectClip();
        cardDiscardClip = CreateCardDiscardClip();
        healClip = CreateHealClip();
        victoryClip = CreateVictoryClip();
        bgmClip = CreateBGMClip();
    }

    #region Play Methods
    public void PlayBGM()
    {
        if (bgmSource == null || bgmClip == null) return;
        if (bgmSource.isPlaying) return;
        bgmSource.clip = bgmClip;
        bgmSource.Play();
    }

    public void StopBGM()
    {
        if (bgmSource != null) bgmSource.Stop();
    }

    public void PlaySlash()
    {
        PlaySFX(slashClip, 1.0f);
    }

    public void PlayDamage()
    {
        PlaySFX(damageClip, 0.95f);
    }

    public void PlayParry()
    {
        PlaySFX(parryClip, 1.0f);
    }

    public void PlaySkill()
    {
        PlaySFX(skillClip, 1.0f);
    }

    public void PlayCardDraw()
    {
        PlaySFX(cardDrawClip, 0.7f);
    }

    public void PlayCardSelect()
    {
        PlaySFX(cardSelectClip, 0.6f);
    }

    public void PlayCardDiscard()
    {
        PlaySFX(cardDiscardClip, 0.65f);
    }

    public void PlayHeal()
    {
        PlaySFX(healClip, 0.85f);
    }

    public void PlayVictory()
    {
        PlaySFX(victoryClip, 1.0f);
    }

    public void PlayError()
    {
        PlaySFX(damageClip, 0.5f);
    }

    public void PlayCardVoice(CardModel card, float vol = 1.0f)
    {
        if (card == null) return;
        PlayCardVoice(card.cardName, vol);
    }

    public void PlayCardVoice(string cardName, float vol = 1.0f)
    {
        if (string.IsNullOrWhiteSpace(cardName)) return;
        string key = NormalizeCardKey(cardName);
        if (string.IsNullOrEmpty(key)) return;

        if (!voiceClipCache.TryGetValue(key, out var clip) || clip == null)
        {
            clip = Resources.Load<AudioClip>("Audio/Voice/" + key);
            if (clip != null)
            {
                voiceClipCache[key] = clip;
            }
        }

        if (clip != null && voiceSource != null)
        {
            voiceSource.PlayOneShot(clip, vol);
        }
    }

    private string NormalizeCardKey(string name)
    {
        string raw = name.Trim().ToLowerInvariant();

        // Trảm variants
        if (raw.Contains("lôi") || raw.Contains("loi")) return "tram_loi";
        if (raw.Contains("hỏa") || raw.Contains("hoa")) return "tram_hoa";
        if (raw.Contains("trảm") || raw.Contains("tram")) return "tram";

        // Đỡ
        if (raw.Contains("đỡ") || raw.Contains("do")) return "do";

        // Bánh Chưng / Hủ Rượu
        if (raw.Contains("bánh chưng") || raw.Contains("banh chung")) return "banh_chung";
        if (raw.Contains("hủ rượu") || raw.Contains("hu ruou") || raw.Contains("rượu")) return "hu_ruou";

        // Cẩm nang tức thời
        if (raw.Contains("diệu kế") || raw.Contains("phá mưu")) return "dieu_ke_pha_muu";
        if (raw.Contains("dụng binh") || raw.Contains("như thần")) return "dung_binh_nhu_than";
        if (raw.Contains("vườn không") || raw.Contains("nhà trống")) return "vuon_khong_nha_trong";
        if (raw.Contains("đột kích") || raw.Contains("trộm lương")) return "dot_kich_trom_luong";
        if (raw.Contains("thách đấu") || raw.Contains("quyết đấu")) return "thach_dau";
        if (raw.Contains("mưa tên") || raw.Contains("liên châu")) return "mua_ten_lien_chau";
        if (raw.Contains("bãi cọc") || raw.Contains("cọc ngầm")) return "bai_coc_ngam";
        if (raw.Contains("mở kho") || raw.Contains("cứu tế")) return "mo_kho_cuu_te";

        // Cẩm nang trì hoãn
        if (raw.Contains("trầm ảo") || raw.Contains("sa bẫy")) return "tram_ao_sa_bay";
        if (raw.Contains("cắt đường") || raw.Contains("đường lương")) return "cat_duong_luong";
        if (raw.Contains("thần sấm") || raw.Contains("báo ứng")) return "than_sam_bao_ung";

        // Trang bị vũ khí
        if (raw.Contains("mường nhạ") || raw.Contains("song cung")) return "song_cung_muong_nha";
        if (raw.Contains("kim quy") || raw.Contains("nỏ thần")) return "no_than_kim_quy";
        if (raw.Contains("thuận thiên") || raw.Contains("thuan thien")) return "kiem_thuan_thien";
        if (raw.Contains("lãng bạc") || raw.Contains("thương ngâu")) return "thuong_ngau_lang_bac";
        if (raw.Contains("nam sơn") || raw.Contains("trường đao")) return "truong_dao_nam_son";
        if (raw.Contains("thần công") || raw.Contains("hồ triều")) return "sung_than_cong_ho_trieu";

        // Trang bị giáp & thú cưỡi
        if (raw.Contains("sơn vi") || raw.Contains("giáp đồng")) return "giap_dong_son_vi";
        if (raw.Contains("mây bện") || raw.Contains("khiên mây")) return "khien_may_ben";
        if (raw.Contains("hoàng tộc") || raw.Contains("áo bào")) return "ao_bao_hoang_toc";
        if (raw.Contains("voi chiến") || raw.Contains("voi")) return "voi_chien_dai_viet";
        if (raw.Contains("thuần nông") || raw.Contains("ngựa trắng")) return "ngua_trang_thuan_nong";
        if (raw.Contains("xích thố")) return "xich_tho";
        if (raw.Contains("phi lực")) return "phi_luc";

        // Kỹ năng tướng
        if (raw.Contains("tiến thoái")) return "tien_thoai";
        if (raw.Contains("cướp bóc")) return "cuop_boc";

        return "";
    }

    private void PlaySFX(AudioClip clip, float vol)
    {
        if (sfxSource == null || clip == null) return;
        sfxSource.PlayOneShot(clip, vol);
    }
    #endregion

    #region Procedural Audio Generators
    private AudioClip CreateSlashClip()
    {
        int sampleRate = 44100;
        float duration = 0.28f;
        int sampleCount = (int)(sampleRate * duration);
        float[] samples = new float[sampleCount];

        for (int i = 0; i < sampleCount; i++)
        {
            float t = (float)i / sampleRate;
            float env = Mathf.Exp(-t * 18f); // Suy giảm nhanh
            // Tiếng rít gió tần số cao giảm dần + tiếng chém
            float freq = Mathf.Lerp(1400f, 320f, t / duration);
            float noise = (UnityEngine.Random.value * 2f - 1f) * 0.45f;
            float sine = Mathf.Sin(2f * Mathf.PI * freq * t) * 0.55f;
            samples[i] = (sine + noise) * env;
        }

        var clip = AudioClip.Create("SFX_Slash", sampleCount, 1, sampleRate, false);
        clip.SetData(samples, 0);
        return clip;
    }

    private AudioClip CreateDamageClip()
    {
        int sampleRate = 44100;
        float duration = 0.35f;
        int sampleCount = (int)(sampleRate * duration);
        float[] samples = new float[sampleCount];

        for (int i = 0; i < sampleCount; i++)
        {
            float t = (float)i / sampleRate;
            float env = Mathf.Exp(-t * 9f);
            float bass = Mathf.Sin(2f * Mathf.PI * 90f * t) * 0.7f;
            float impact = (UnityEngine.Random.value * 2f - 1f) * 0.3f * Mathf.Exp(-t * 25f);
            samples[i] = (bass + impact) * env;
        }

        var clip = AudioClip.Create("SFX_Damage", sampleCount, 1, sampleRate, false);
        clip.SetData(samples, 0);
        return clip;
    }

    private AudioClip CreateParryClip()
    {
        int sampleRate = 44100;
        float duration = 0.45f;
        int sampleCount = (int)(sampleRate * duration);
        float[] samples = new float[sampleCount];

        for (int i = 0; i < sampleCount; i++)
        {
            float t = (float)i / sampleRate;
            float env = Mathf.Exp(-t * 6f);
            // Tiếng kim loại ngân vang hòa âm (1100Hz + 2200Hz + 3300Hz)
            float metal1 = Mathf.Sin(2f * Mathf.PI * 1150f * t) * 0.5f;
            float metal2 = Mathf.Sin(2f * Mathf.PI * 2300f * t) * 0.3f;
            float metal3 = Mathf.Sin(2f * Mathf.PI * 3450f * t) * 0.15f;
            samples[i] = (metal1 + metal2 + metal3) * env;
        }

        var clip = AudioClip.Create("SFX_Parry", sampleCount, 1, sampleRate, false);
        clip.SetData(samples, 0);
        return clip;
    }

    private AudioClip CreateSkillClip()
    {
        int sampleRate = 44100;
        float duration = 0.65f;
        int sampleCount = (int)(sampleRate * duration);
        float[] samples = new float[sampleCount];

        for (int i = 0; i < sampleCount; i++)
        {
            float t = (float)i / sampleRate;
            float env = Mathf.Sin(Mathf.Clamp01(t / duration) * Mathf.PI);
            // Thang âm dâng trào huyền ảo (ngũ cung cổ phong)
            float freq = Mathf.Lerp(261.6f, 659.2f, t / duration);
            float wave = Mathf.Sin(2f * Mathf.PI * freq * t) * 0.6f + Mathf.Sin(2f * Mathf.PI * freq * 2f * t) * 0.25f;
            samples[i] = wave * env;
        }

        var clip = AudioClip.Create("SFX_Skill", sampleCount, 1, sampleRate, false);
        clip.SetData(samples, 0);
        return clip;
    }

    private AudioClip CreateCardDrawClip()
    {
        int sampleRate = 44100;
        float duration = 0.12f;
        int sampleCount = (int)(sampleRate * duration);
        float[] samples = new float[sampleCount];

        for (int i = 0; i < sampleCount; i++)
        {
            float t = (float)i / sampleRate;
            float env = Mathf.Exp(-t * 22f);
            float noise = (UnityEngine.Random.value * 2f - 1f) * 0.5f;
            float click = Mathf.Sin(2f * Mathf.PI * 800f * t) * 0.3f;
            samples[i] = (noise + click) * env;
        }

        var clip = AudioClip.Create("SFX_CardDraw", sampleCount, 1, sampleRate, false);
        clip.SetData(samples, 0);
        return clip;
    }

    private AudioClip CreateCardSelectClip()
    {
        int sampleRate = 44100;
        float duration = 0.08f;
        int sampleCount = (int)(sampleRate * duration);
        float[] samples = new float[sampleCount];

        for (int i = 0; i < sampleCount; i++)
        {
            float t = (float)i / sampleRate;
            float env = Mathf.Exp(-t * 35f);
            float tone = Mathf.Sin(2f * Mathf.PI * 1200f * t) * 0.6f;
            samples[i] = tone * env;
        }

        var clip = AudioClip.Create("SFX_CardSelect", sampleCount, 1, sampleRate, false);
        clip.SetData(samples, 0);
        return clip;
    }

    private AudioClip CreateCardDiscardClip()
    {
        int sampleRate = 44100;
        float duration = 0.16f;
        int sampleCount = (int)(sampleRate * duration);
        float[] samples = new float[sampleCount];

        for (int i = 0; i < sampleCount; i++)
        {
            float t = (float)i / sampleRate;
            float env = Mathf.Exp(-t * 20f);
            float noise = (UnityEngine.Random.value * 2f - 1f) * 0.4f;
            float whoosh = Mathf.Sin(2f * Mathf.PI * Mathf.Lerp(450f, 150f, t / duration) * t) * 0.4f;
            samples[i] = (noise + whoosh) * env;
        }

        var clip = AudioClip.Create("SFX_CardDiscard", sampleCount, 1, sampleRate, false);
        clip.SetData(samples, 0);
        return clip;
    }

    private AudioClip CreateHealClip()
    {
        int sampleRate = 44100;
        float duration = 0.55f;
        int sampleCount = (int)(sampleRate * duration);
        float[] samples = new float[sampleCount];

        for (int i = 0; i < sampleCount; i++)
        {
            float t = (float)i / sampleRate;
            float env = Mathf.Sin(Mathf.Clamp01(t / duration) * Mathf.PI);
            float tone1 = Mathf.Sin(2f * Mathf.PI * 523.25f * t) * 0.4f; // C5
            float tone2 = Mathf.Sin(2f * Mathf.PI * 659.25f * t) * 0.3f; // E5
            float tone3 = Mathf.Sin(2f * Mathf.PI * 783.99f * t) * 0.3f; // G5
            samples[i] = (tone1 + tone2 + tone3) * env;
        }

        var clip = AudioClip.Create("SFX_Heal", sampleCount, 1, sampleRate, false);
        clip.SetData(samples, 0);
        return clip;
    }

    private AudioClip CreateVictoryClip()
    {
        int sampleRate = 44100;
        float duration = 1.2f;
        int sampleCount = (int)(sampleRate * duration);
        float[] samples = new float[sampleCount];

        for (int i = 0; i < sampleCount; i++)
        {
            float t = (float)i / sampleRate;
            float env = Mathf.Exp(-t * 1.5f);
            float drum = Mathf.Sin(2f * Mathf.PI * 80f * t) * Mathf.Exp(-t * 4f) * 0.6f;
            float fanfare = Mathf.Sin(2f * Mathf.PI * 587.33f * t) * 0.4f; // D5
            samples[i] = (drum + fanfare) * env;
        }

        var clip = AudioClip.Create("SFX_Victory", sampleCount, 1, sampleRate, false);
        clip.SetData(samples, 0);
        return clip;
    }

    private AudioClip CreateBGMClip()
    {
        int sampleRate = 22050; // Tiết kiệm bộ nhớ cho đoạn nhạc 8 giây lặp
        float duration = 8.0f;
        int sampleCount = (int)(sampleRate * duration);
        float[] samples = new float[sampleCount];

        // Ngũ cung Việt Nam: C3, D3, F3, G3, A3, C4, D4, F4
        float[] pentatonic = { 130.81f, 146.83f, 174.61f, 196.00f, 220.00f, 261.63f, 293.66f, 349.23f };

        for (int i = 0; i < sampleCount; i++)
        {
            float t = (float)i / sampleRate;

            // Nhịp trống trận (mỗi 0.5s có 1 tiếng trống)
            float drumBeat = t % 0.5f;
            float drumEnv = Mathf.Exp(-drumBeat * 16f);
            float drum = Mathf.Sin(2f * Mathf.PI * 75f * drumBeat) * drumEnv * 0.28f;

            // Giai điệu cổ phong đổi nốt mỗi 1 giây
            int noteIndex = ((int)(t * 2)) % pentatonic.Length;
            float noteFreq = pentatonic[noteIndex];
            float noteT = t % 0.5f;
            float noteEnv = Mathf.Sin(Mathf.Clamp01(noteT / 0.5f) * Mathf.PI);
            float melody = (Mathf.Sin(2f * Mathf.PI * noteFreq * t) + 0.35f * Mathf.Sin(2f * Mathf.PI * noteFreq * 2f * t)) * noteEnv * 0.16f;

            samples[i] = drum + melody;
        }

        var clip = AudioClip.Create("BGM_Battle", sampleCount, 1, sampleRate, false);
        clip.SetData(samples, 0);
        return clip;
    }
    #endregion
}
