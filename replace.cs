using System;
using System.IO;
using System.Text.RegularExpressions;

class Program
{
    static void Main()
    {
        string path = "Assets/Scripts/Battle2v2UI.cs";
        string content = File.ReadAllText(path);
        string pattern = @"(?s)// NẾU client đang TỰ ĐẾM.*?if \(!isHandlingSpecialPromptLocally\)\s*\{([^}]*?)\}[^}]*?if \(turnTimer <= 0f\)";
        
        Match m = Regex.Match(content, pattern);
        if (m.Success)
        {
            string inner = m.Groups[1].Value;
            string replace = inner + "\r\n\r\n            if (turnTimer <= 0f)";
            content = content.Substring(0, m.Index) + replace + content.Substring(m.Index + m.Length);
            File.WriteAllText(path, content);
            Console.WriteLine("Replaced!");
        }
        else
        {
            Console.WriteLine("No match!");
        }
    }
}
