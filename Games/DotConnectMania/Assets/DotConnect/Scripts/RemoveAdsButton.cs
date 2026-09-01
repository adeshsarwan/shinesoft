using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class RemoveAdsButton : MonoBehaviour
{
    public Text removeAdsText;
    public GameObject removeAdsButton;
    void Start()
    {
        if (PlayerPrefs.GetInt("premium", 0) == 1)
        {
            removeAdsButton.SetActive(false);
        }
    }

    // Update is called once per frame
    void Update()
    {
        removeAdsText.text = $"REMOVE ADS {IAPManager.instance.costTexts[0]}";
        if (IAPManager.isIntialized && PlayerPrefs.GetInt("premium", 0) != 1)
        {
            if (IAPManager.CheckRemoveAdsSubscription(IAPManager.instance.m_ConsumableIds[0]))    // pass the remove ads skuid
            {
                RemoveAdsCB(1);  // remove ads call back
            }
        }

    }
    public void RemoveAdsBTN()
    {
        IAPManager.BuyProductID("com.flowdotconnectmania.removeads", 1, RemoveAdsCB);
    }
    void RemoveAdsCB(int val)
    {
        IAPManager.instance.isPremium = true;
        PlayerPrefs.SetInt("premium", 1);
        removeAdsButton.SetActive(false);
    }
}
