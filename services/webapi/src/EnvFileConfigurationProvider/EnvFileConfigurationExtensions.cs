using System;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Configuration.EnvFile;

namespace Microsoft.Extensions.Configuration
{
    public static class EnvFileConfigurationExtensions
    {
        public static IConfigurationBuilder AddEnvFile(this IConfigurationBuilder builder, string path)
        {
            return AddEnvFile(builder, fileProvider: null, path, optional: false, reloadOnChange: false);
        }

        public static IConfigurationBuilder AddEnvFile(this IConfigurationBuilder builder, string path, bool optional)
        {
            return AddEnvFile(builder, fileProvider: null, path, optional, reloadOnChange: false);
        }

        public static IConfigurationBuilder AddEnvFile(this IConfigurationBuilder builder, string path, bool optional, bool reloadOnChange)
        {
            return AddEnvFile(builder, fileProvider: null, path, optional, reloadOnChange);
        }

        public static IConfigurationBuilder AddEnvFile(this IConfigurationBuilder builder, IFileProvider fileProvider, string path, bool optional, bool reloadOnChange)
        {
            return builder.AddEnvFile(s =>
            {
                s.FileProvider = fileProvider;
                s.Path = path;
                s.Optional = optional;
                s.ReloadOnChange = reloadOnChange;
                s.ResolveFileProvider();
            });
        }

        public static IConfigurationBuilder AddEnvFile(this IConfigurationBuilder builder, Action<EnvFileConfigurationSource> configurationSource)
            => builder.Add(configurationSource);
    }
}
