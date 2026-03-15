using System;
using System.Windows.Forms;

namespace MdExplorerPreview.AutoUnblocker
{
    internal static class Program
    {
        [STAThread]
        private static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            var settingsPath = CommandLineOptions.ResolveSettingsPath(args);
            var settings = AutoUnblockerSettingsStore.LoadOrCreate(settingsPath);
            using (var logger = AutoUnblockerLogger.Create(settings))
            using (var singleInstanceGuard = SingleInstanceGuard.TryAcquire(settingsPath))
            {
                if (singleInstanceGuard == null)
                {
                    logger.Log("warn", "single-instance", null, null, null, false, "ignored", "Another instance is already running for the same settings path.");
                    return;
                }

                logger.Log("info", "startup", settingsPath, null, null, false, "starting", "Auto-unblocker is starting.");
                Application.Run(new AutoUnblockerApplicationContext(settings, settingsPath, logger, singleInstanceGuard));
            }
        }
    }
}
