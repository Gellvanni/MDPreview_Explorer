using System.Windows.Forms;

namespace MdExplorerPreview.AutoUnblocker
{
    internal sealed class AutoUnblockerApplicationContext : ApplicationContext
    {
        private readonly AutoUnblockerHost host;
        private readonly AutoUnblockerLogger logger;
        private readonly SingleInstanceGuard singleInstanceGuard;
        private bool disposed;

        public AutoUnblockerApplicationContext(
            AutoUnblockerSettings settings,
            string settingsPath,
            AutoUnblockerLogger logger,
            SingleInstanceGuard singleInstanceGuard)
        {
            this.logger = logger;
            this.singleInstanceGuard = singleInstanceGuard;
            host = new AutoUnblockerHost(settings, settingsPath, logger);

            if (!host.Start())
            {
                ExitThread();
            }
        }

        protected override void ExitThreadCore()
        {
            DisposeResources();
            base.ExitThreadCore();
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                DisposeResources();
            }

            base.Dispose(disposing);
        }

        private void DisposeResources()
        {
            if (disposed)
            {
                return;
            }

            disposed = true;
            host.Dispose();
            logger.Log("info", "shutdown", null, null, null, false, "stopped", "Auto-unblocker is shutting down.");
            singleInstanceGuard.Dispose();
        }
    }
}
