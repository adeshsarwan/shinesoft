using UnityEngine;
using UnityEditor;

public class CustomBuildWindow : EditorWindow
{
    [InitializeOnLoadMethod]
    private static void InitOnLoad()
    {
        // hijack the Build button in Unity's Build Settings window
        BuildPlayerWindow.RegisterGetBuildPlayerOptionsHandler(OnGetBuildPlayerOptions);
        BuildPlayerWindow.RegisterBuildPlayerHandler(OnBuildPlayer);
    }

    private static BuildPlayerOptions OnGetBuildPlayerOptions(BuildPlayerOptions buildPlayerOptions)
    {
        OpenCustomBuildWindow(buildPlayerOptions);
        return buildPlayerOptions;
    }

    private static void OnBuildPlayer(BuildPlayerOptions buildPlayerOptions)
    {
        // Do nothing here as the build is triggered from the Build button of the custom window
    }

    public static CustomBuildWindow OpenCustomBuildWindow(BuildPlayerOptions buildPlayerOptions)
    {
        var w = EditorWindow.GetWindow<CustomBuildWindow>();
        // store initial options from Unity's Build window, such as if "Build" or "Build And Run" was pressed
        w.buildOptions = buildPlayerOptions.options;
        w.Show();
        return w;
    }

    private BuildOptions buildOptions;

    // Checkbox states
    private bool checkbox1 = false;
    private bool checkbox2 = false;
    private bool checkbox3 = false;
    private bool checkbox4 = false;
    private bool checkbox5 = false;
    private bool checkbox6 = false;
    private bool checkbox7 = false;
    private bool checkbox8 = false;

    private void OnEnable()
    {
        titleContent = new GUIContent("Custom Build Settings");
    }

    private void OnGUI()
    {
        // Add checkboxes
        checkbox1 = EditorGUILayout.Toggle("Test Mode Check", checkbox1);
        checkbox2 = EditorGUILayout.Toggle("Server Url Check", checkbox2);
        checkbox3 = EditorGUILayout.Toggle("Google Ad Ids Check", checkbox3);
        checkbox4 = EditorGUILayout.Toggle("Package Name Check", checkbox4);
        checkbox5 = EditorGUILayout.Toggle("Keystore Check", checkbox5);
        checkbox6 = EditorGUILayout.Toggle("Google Service JSON", checkbox6);
        checkbox7 = EditorGUILayout.Toggle("White eye check in Adjust", checkbox7);
        checkbox8 = EditorGUILayout.Toggle("PBL version checked", checkbox8);
        // Build button
        string buildButtonLabel = (buildOptions & BuildOptions.AutoRunPlayer) == 0 ? "Build" : "Build And Run";
        GUI.enabled = checkbox1 && checkbox2 && checkbox3 && checkbox4 && checkbox5 && checkbox6 && checkbox7 && checkbox8; // Enable button only if all checkboxes are checked
        if (GUILayout.Button(buildButtonLabel))
        {
            Close(); // Close the window when starting a build
            DoBuild();
        }
        GUI.enabled = true; // Reset the GUI.enabled state to avoid affecting other UI elements
    }

    private void DoBuild()
    {
        var buildPlayerOptions = new BuildPlayerOptions();
        buildPlayerOptions.options = buildOptions;
        try
        {
            // Get default scene list and options from Unity's Build Settings window
            // Prompts for the build output location and stores it in buildPlayerOptions.locationPathName
            buildPlayerOptions = BuildPlayerWindow.DefaultBuildMethods.GetBuildPlayerOptions(buildPlayerOptions);
        }
        catch (BuildPlayerWindow.BuildMethodException)
        {
            // Hide an exception from the log if the user cancels the build location prompt
            return;
        }

        // Modify the buildPlayerOptions or project with values set in the window

        // Execute the build (using the default build method in this example)
        BuildPlayerWindow.DefaultBuildMethods.BuildPlayer(buildPlayerOptions);
    }
}
