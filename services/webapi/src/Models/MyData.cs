using Swashbuckle.AspNetCore.Annotations;

using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Webapi.Models
{
    public class MyData : MyDataContent
    {
        public MyData() { }
        internal MyData(MyDataContent content)
        {
            this.Description = content.Description;
            this.IsEnabled = content.IsEnabled;
            this.Title = content.Title;
            this.TimeStampUtc = DateTime.UtcNow;
        }

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [SwaggerSchema("The data identifier", ReadOnly = true)]
        public int MyDataId { get; set; }

        [SwaggerSchema("When the data was first added", ReadOnly = true)]
        public DateTime TimeStampUtc { get; set; }

        [Timestamp]
        [SwaggerSchema("Row version identifier for optimistic concurrency ", ReadOnly = true)]
        public byte[] RowVersion { get; set; }
    }

    //User modifiable portion of the data
    public class MyDataContent
    {
        public string Title { get; set; }
        public string Description { get; set; }
        public bool IsEnabled { get; set; }
    }
}
