using System;
using System.Linq;

namespace webapi.tests.Utility
{
    /// <summary>
    /// Detect if we are running in the context of live unit tests and skip running the test if requested.
    /// </summary>
    internal static class LiveUnitTestUtil
    {
        private static readonly bool SLiveUnitTestRuntimeLoaded = AppDomain.CurrentDomain.GetAssemblies()
            .Any(a => a.GetName().Name == "Microsoft.CodeAnalysis.LiveUnitTesting.Runtime");

        public static string SkipIfLiveUnitTest(bool skip)
        {
            if (SLiveUnitTestRuntimeLoaded && skip)
            {
                return "Test excluded from Live Unit Testing";
            }
            return null;
        }
    }
}
