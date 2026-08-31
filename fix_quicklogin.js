const fs = require('fs');
let code = fs.readFileSync('Assets/Scripts/AuthUI.cs', 'utf8');

const updateCode = 
    private void Update()
    {
#if UNITY_EDITOR || UNITY_STANDALONE_WIN
        if (UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.Alpha1)) QuickLogin(1);
        else if (UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.Alpha2)) QuickLogin(2);
        else if (UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.Alpha3)) QuickLogin(3);
        else if (UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.Alpha4)) QuickLogin(4);
        else if (UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.Alpha5)) QuickLogin(5);
        else if (UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.Alpha6)) QuickLogin(6);
        else if (UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.Alpha7)) QuickLogin(7);
        else if (UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.Alpha8)) QuickLogin(8);
        else if (UnityEngine.Input.GetKeyDown(UnityEngine.KeyCode.Alpha9)) QuickLogin(9);
#endif
    }

    private void QuickLogin(int num)
    {
        if (emailInput != null) emailInput.text = "vdthanh22" + num + "@gmail.com";
        if (passwordInput != null) passwordInput.text = "matkhau123";
        SetRegisterMode(false);
        Submit();
    }
;

code = code.replace(
    'private void Start()',
    updateCode + '\n    private void Start()'
);

fs.writeFileSync('Assets/Scripts/AuthUI.cs', code);
