using System;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Configuration;
using Azure.Identity;

namespace Webapi
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args)
        {
            return Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.ConfigureAppConfiguration((context, configBuilder) =>
                    {
                        if (context.HostingEnvironment.IsDevelopment())
                        {
                            configBuilder.AddEnvFile("development.env");
                        }
                        else if (context.HostingEnvironment.IsStaging() || context.HostingEnvironment.IsProduction())
                        {
                            var builtConfig = configBuilder.Build();
                            // If the SQLCONNSTRING is not available in the config already read it from KeyVault.
                            // This would be the case for a deployment to Azure. Deployment to Arc will have the SQLCONNSTRING as an app config
                            if (builtConfig.GetValue<string>("SQLCONNSTRING") == "")
                            {
                                configBuilder.AddAzureKeyVault(new Uri($"https://{builtConfig["KeyVaultName"]}.vault.azure.net/"), new DefaultAzureCredential());
                            }
                        }
                    });

                    webBuilder.UseStartup<Startup>();
                });
        }
    }
}
