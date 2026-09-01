using UnityEngine;
using UnityEngine.UI;

namespace BizzyBeeGames.DotConnect
{
    [RequireComponent(typeof(Button))]
    public class UnlockLevelAdButton : MonoBehaviour
    {
        #region Inspector Variables

        [SerializeField] public GameObject noadpopup;   // shown if no ad is ready
        [SerializeField] public Popup      thisPopup;   // the unlock_level_locked popup, to close on success

        #endregion

        public Button Button { get { return gameObject.GetComponent<Button>(); } }

        private void Awake()
        {
            Button.onClick.AddListener(OnClick);
        }

        private void OnClick()
        {
            if (GoogleAdsManager.Instance.CanShowRewardAd())
            {
                int levelNumber = GameManager.Instance.PendingUnlockLevelData.LevelIndex + 1;

                GoogleAdsManager.Instance.ShowRewardAd("unlock_level", "level_unlock", levelNumber, OnRewardAdGranted);
            }
            else
            {
                noadpopup.SetActive(true);
            }
        }

        private void OnRewardAdGranted()
        {
            if (thisPopup != null)
                thisPopup.Hide(false); // goes through Popup's state machine so it can be shown again

            GameManager.Instance.UnlockPendingLevelViaAd();
        }
    }
}