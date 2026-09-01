using System.Threading.Tasks;
using Firebase;
using UnityEngine;

public class FirebaseManager : MonoBehaviour
{
    public static FirebaseManager Instance;

    private bool firebaseReady = false;
    public bool IsReady => firebaseReady;

    private void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            Destroy(gameObject);
            return;
        }

        InitializeFirebase();
    }

    private void InitializeFirebase()
    {
        FirebaseApp.CheckAndFixDependenciesAsync().ContinueWith(task =>
        {
            var dependencyStatus = task.Result;

            if (dependencyStatus == DependencyStatus.Available)
            {
                FirebaseApp app = FirebaseApp.DefaultInstance;
                firebaseReady = true;
                Debug.Log("Firebase initialized successfully.");
            }
            else
            {
                firebaseReady = false;
                Debug.LogError(
                    "Could not resolve Firebase dependencies: " +
                    dependencyStatus
                );
            }
        }, TaskScheduler.FromCurrentSynchronizationContext()); 
    }
}