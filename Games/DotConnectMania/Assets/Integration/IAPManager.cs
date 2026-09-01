/*using System.Collections;
using System.Collections.Generic;*/
using UnityEngine;
using UnityEngine.Purchasing;
using System;

public class IAPManager : MonoBehaviour, IStoreListener
{
    [SerializeField] public string[] m_ConsumableIds;
    public string[] costTexts;

    public static IStoreController _StoreController;          // The Unity Purchasing system.
    public static IExtensionProvider _StoreExtensionProvider; // The store-specific Purchasing subsystems.
    private static int mQuantity;
    private static Action<int> OnPurchaseComplete = null;

    public static IAPManager instance;

    public bool isPremium;

    public static bool isIntialized = false;

    private void Awake()
    {
        if (instance != null && instance != this)
        {
            Destroy(gameObject);
        }
        else
        {
            instance = this;
            DontDestroyOnLoad(gameObject);
        }

        if (PlayerPrefs.GetInt("premium", 0) == 1)
        {
            isPremium = true;
        }
    }

    void Start()
    {
        // If we haven't set up the Unity Purchasing reference
        if (_StoreController == null)
        {
            // Begin to configure our connection to Purchasing
            InitializePurchasing();
        }
    }

    TextMesh cText;

    public void InitializePurchasing()
    {
        // If we have already connected to Purchasing ...        
        if (IsInitialized())
        {
            // ... we are done here.
            return;
        }

        // Create a builder, first passing in a suite of Unity provided stores.
        var builder = ConfigurationBuilder.Instance(StandardPurchasingModule.Instance());

        for (int i = 0; i < m_ConsumableIds.Length; i++)
        {
            // Continue adding the non-consumable product.
            builder.AddProduct(m_ConsumableIds[i], ProductType.Consumable);
        }

        // Kick off the remainder of the set-up with an asynchrounous call, passing the configuration 
        // and this class' instance. Expect a response either in OnInitialized or OnInitializeFailed.
        UnityPurchasing.Initialize(this, builder);


    }
    public static bool CheckRemoveAdsSubscription(string productId)
    {
        Product product = _StoreController.products.WithID(productId);
        if (product == null)
            Debug.Log("gggg");

        if (product != null && product.hasReceipt)
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    private static bool IsInitialized()
    {
        // Only say we are initialized if both the Purchasing references are set.
        return _StoreController != null && _StoreExtensionProvider != null;
    }

    public void OnInitialized(IStoreController controller, IExtensionProvider extensions)
    {
        // Purchasing has succeeded initializing. Collect our Purchasing references.
        Debug.Log("OnInitialized: PASS");

        // Overall Purchasing system, configured with products for this application.
        _StoreController = controller;
        // Store specific subsystem, for accessing device-specific store features.
        _StoreExtensionProvider = extensions;

        for (int k = 0; k < m_ConsumableIds.Length; k++)
        {
            Debug.Log("price   " + k + "  " + _StoreController.products.WithID(m_ConsumableIds[k]).metadata.localizedPriceString);
            costTexts[k] = _StoreController.products.WithID(m_ConsumableIds[k]).metadata.localizedPriceString;
            //MainMenuManager.Instance.costs[k].text = costTexts[k];
        }
        isIntialized = true;

    }

    public void OnInitializeFailed(InitializationFailureReason error)
    {
        // Purchasing set-up has not succeeded. Check error for reason. Consider sharing this reason with the user.
        Debug.Log("OnInitializeFailed InitializationFailureReason:" + error);
    }

    public static void BuyProductID(string productId, int quantity, Action<int> callback)
    {
        // If Purchasing has been initialized ...
        if (IsInitialized())
        {
            // ... look up the Product reference with the general product identifier and the Purchasing 
            // system's products collection.
            Product product = _StoreController.products.WithID(productId);

            // If the look up found a product for this device's store and that product is ready to be sold ... 
            if (product != null && product.availableToPurchase)
            {
                Debug.Log(string.Format("Purchasing product asychronously: '{0}'", product.definition.id));
                // ... buy the product. Expect a response either through ProcessPurchase or OnPurchaseFailed 
                // asynchronously.
                mQuantity = quantity;
                OnPurchaseComplete = callback;
                _StoreController.InitiatePurchase(product);
            }
            // Otherwise ...
            else
            {
                // ... report the product look-up failure situation  
                Debug.Log("BuyProductID: FAIL. Not purchasing product, either is not found or is not available for purchase");
            }
        }
        // Otherwise ...
        else
        {
            // ... report the fact Purchasing has not succeeded initializing yet. Consider waiting longer or 
            // retrying initiailization.
            Debug.Log("BuyProductID FAIL. Not initialized.");
        }
    }

    public PurchaseProcessingResult ProcessPurchase(PurchaseEventArgs args)
    {

        Debug.Log(string.Format("ProcessPurchase: PASS. Product: '{0}'", args.purchasedProduct.definition.id));
        OnPurchaseComplete?.Invoke(mQuantity);
        // Return a flag indicating whether this product has completely been received, or if the application needs 
        // to be reminded of this purchase at next app launch. Use PurchaseProcessingResult.Pending when still 
        // saving purchased products to the cloud, and when that save is delayed. 
        return PurchaseProcessingResult.Complete;
    }

    public void OnPurchaseFailed(Product product, PurchaseFailureReason failureReason)
    {
        // A product purchase attempt did not succeed. Check failureReason for more detail. Consider sharing 
        // this reason with the user to guide their troubleshooting actions.
        Debug.Log(string.Format("OnPurchaseFailed: FAIL. Product: '{0}', PurchaseFailureReason: {1}", product.definition.storeSpecificId, failureReason));
    }

    public void OnInitializeFailed(InitializationFailureReason error, string message)
    {
        throw new NotImplementedException();
    }
}
