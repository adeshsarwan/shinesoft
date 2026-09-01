using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(fileName = "APIData", menuName = "APIData")]
public class APIData : ScriptableObject
{
    [Space(5)]
    [Header("Enable Sdks")]
    public bool isAdEnabled;

    //ad data
    [Space(5)]
    [Header("AdIds")]
    public string interstitialAndroidAdID;
    public string rewardedAndroidAdID;
    public string appOpenAndroidAdID;
    public string bannerAndroidAdID;


    //game share url
    [Space(5)]
    [Header("GameShare")]
    public string shareURL;
}


