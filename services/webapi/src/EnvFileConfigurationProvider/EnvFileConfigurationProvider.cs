using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;

namespace Microsoft.Extensions.Configuration.EnvFile
{
    internal class EnvFileConfigurationProvider : FileConfigurationProvider
    {
        public EnvFileConfigurationProvider(EnvFileConfigurationSource source) : base(source) { }

        public override void Load(Stream stream)
        {
            var data = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            var doubleQuotedValueRegex = new Regex(@"""([^""\\]*(?:\\.[^""\\]*)*)""");
            var singleQuotedValueRegex = new Regex(@"'([^'\\]*(?:\\.[^'\\]*)*)'");

            using (var reader = new StreamReader(stream))
            {
                while (reader.Peek() != -1)
                {
                    string line = reader.ReadLine().Trim();
                    if (string.IsNullOrWhiteSpace(line))
                    {
                        continue;
                    }

                    if (line.StartsWith("#", StringComparison.Ordinal))
                    {
                        continue; // It is a comment
                    }

                    int separator = line.IndexOf('=', StringComparison.Ordinal);
                    if (separator <= 0 || separator == (line.Length-1))
                    {
                        continue; // Multi-line values are not supported by this implementation.
                    }

                    string key = line.Substring(0, separator).Trim();
                    if (string.IsNullOrWhiteSpace(key))
                    {
                        throw new FormatException("Configuration setting name should not be empty");
                    }

                    string value = line.Substring(separator + 1).Trim();

                    var doubleQuotedValue = doubleQuotedValueRegex.Match(value);
                    if (doubleQuotedValue.Success)
                    {
                        value = doubleQuotedValue.Groups[1].Value;
                    }
                    else
                    {
                        var singleQuotedValue = singleQuotedValueRegex.Match(value);
                        if (singleQuotedValue.Success)
                        {
                            value = singleQuotedValue.Groups[1].Value;
                        }
                        else
                        {
                            int commentStart = value.IndexOf(" #", StringComparison.Ordinal);
                            if (commentStart > 0)
                            {
                                value = value.Substring(0, commentStart);
                            }
                        }
                    }

                    data[key] = value;
                }
            }

            Data = data;
        }
    }
}