using AutoFixture;

using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;

using System;
using System.Data.Common;

namespace webapi.tests.Utility
{
    /// <summary>
    /// Customization for AutoDataNSubstituteAttribute class to use in memory SQLite database
    /// </summary>
    /// <typeparam name="T">Your DbContext</typeparam>
    internal class UseSqliteMemoryDb<T> : ICustomization, IDisposable
        where T : DbContext
    {
        private readonly DbConnection _connection;

        public UseSqliteMemoryDb()
        {
            this._connection = new SqliteConnection("Filename=:memory:");
            this._connection.Open();
        }
        public void Customize(IFixture fixture)
        {
            //Create a customization to generate in memory sqlite options for connection options.
            fixture.Customize<DbContextOptions<T>>(composer =>
            {
                return composer.FromFactory(() =>
                {
                    DbContextOptions<T> options = new DbContextOptionsBuilder<T>()
                    .UseSqlite(this._connection)
                    .Options;

                    return options;
                }).OmitAutoProperties();
            });

            //Turn off auto properties so the dbsets don't get overwritten by mocks
            //Make sure migrations are applied to the in memory database.
            fixture.Customize<T>(composer => composer.OmitAutoProperties()
                .Do(dbContext => dbContext.Database.EnsureCreated()));
        }

        public void Dispose()
        {
            this._connection?.Dispose();
        }
    }
}

