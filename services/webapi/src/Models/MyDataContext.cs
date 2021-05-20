using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;

namespace Webapi.Models
{
    public class MyDataContext : DbContext
    {
        public MyDataContext(DbContextOptions<MyDataContext> options) : base(options)
        {
        }
        public DbSet<MyData> MyData { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<MyData>()
                .HasKey(d => d.MyDataId);

            modelBuilder.Entity<MyData>().Property(p => p.RowVersion)
                .IsRowVersion()
                .IsConcurrencyToken();

            if (this.Database.IsSqlServer())
            {
                modelBuilder.Entity<MyData>().Property(p => p.TimeStampUtc)
                     .HasDefaultValueSql("getutcdate()")
                     .ValueGeneratedOnAdd()
                     .Metadata.SetAfterSaveBehavior(PropertySaveBehavior.Throw);
            }
        }
    }
}