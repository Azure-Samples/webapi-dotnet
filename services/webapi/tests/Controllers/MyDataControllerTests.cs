using AutoFixture;
using AutoFixture.Xunit2;

using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

using webapi.tests.Utility;

using Webapi.Controllers;
using Webapi.Models;

using Xunit;

namespace webapi.tests.Controllers
{
    public class MyDataControllerTests
    {
        /// <summary>
        /// This class customizes AutoDataNSubstituteAttribute to use SqlliteMemory database
        /// Alternatively you can use [AutoDataNSubstituteAttribute(typeof(UseSqliteMemoryDb<MyDataContext>)]
        /// </summary>
        public class AutoData_SqlMemAttribute : AutoDataNSubstituteAttribute
        {
            public AutoData_SqlMemAttribute() : base(typeof(UseSqliteMemoryDb<MyDataContext>))
            { }
        }

        [Theory, AutoData_SqlMem]
        public void Get_When_Less_Than_10_Returns_All_Records([Frozen] MyDataContext context, MyDataController controller)
        {
            IEnumerable<MyData> res = controller.Get();
            int retrievedCount = res.Count();

            int itemsInDb = context.MyData.Take(10).ToArray().Length;

            Assert.Equal(itemsInDb, retrievedCount);
        }

        [Theory, AutoData_SqlMem]
        public void Get_When_More_Than_10_Reutnrs_First_10([Frozen] MyDataContext context, MyDataController controller)
        {
            var fixture = new Fixture();
            var extraData = fixture.CreateMany<MyData>(30).ToList();
            extraData.ForEach(data => data.MyDataId = 0);

            context.MyData.AddRange(extraData);
            context.SaveChanges();

            int totalCount = context.MyData.Count();

            Assert.True(totalCount > 10);

            IEnumerable<MyData> res = controller.Get();
            int retrievedCount = res.Count();
            Assert.Equal(10, retrievedCount);
        }

        [Theory, AutoData_SqlMem]
        public async Task GetByID_Valid_ID_Returns_Record([Frozen] MyDataContext context, MyDataController controller, MyData testData)
        {
            byte[] origRowVersion = testData.RowVersion;

            testData.MyDataId = 0;
            context.Add(testData);
            context.SaveChanges();

            ActionResult<MyData> res = await controller.GetById(testData.MyDataId);


            Assert.Equal(testData.MyDataId, res.Value.MyDataId);
            Assert.NotEqual(origRowVersion, res.Value.RowVersion);
        }

        [Theory, AutoData_SqlMem]
        public async Task GetByID_Invalid_ID_Returns_404([Frozen] MyDataContext context, MyDataController controller, int testId)
        {
            MyData data = context.MyData.Find(testId);
            if (data != null)
            {
                context.MyData.Remove(data);
                context.SaveChanges();
            }

            ActionResult<MyData> res = await controller.GetById(testId);
            Assert.Null(res.Value);
            Assert.IsAssignableFrom<NotFoundResult>(res.Result);
        }

        [Theory, AutoData_SqlMem]
        public async Task AddNewData_Adds_Data_To_Database([Frozen] MyDataContext context, MyDataController controller, MyData testData)
        {
            testData.MyDataId = 0;
            IActionResult res = await controller.AddNewData(testData);

            Assert.IsAssignableFrom<CreatedAtActionResult>(res);
            Assert.IsAssignableFrom<MyData>(((CreatedAtActionResult)res).Value);

            var returnedData = ((ObjectResult)res).Value as MyData;
            Assert.NotNull(returnedData);

            MyData fromDatabase = context.MyData.Find(returnedData.MyDataId);

            Assert.NotNull(fromDatabase);
            Assert.Equal(fromDatabase.MyDataId, returnedData.MyDataId);
            Assert.Equal(fromDatabase.Title, returnedData.Title);
            Assert.Equal(fromDatabase.Description, returnedData.Description);
            Assert.Equal(fromDatabase.IsEnabled, returnedData.IsEnabled);
            Assert.Equal(fromDatabase.RowVersion, returnedData.RowVersion);
            Assert.Equal(fromDatabase.TimeStampUtc, returnedData.TimeStampUtc);
        }


        [Theory, AutoData_SqlMem]
        public async Task UpdateData_Will_Update_An_Existing_Entity([Frozen] MyDataContext context, MyDataController controller, MyData testData, string newTitle)
        {
            //Add the test data to the database and then detach it
            testData.MyDataId = 0;
            context.MyData.Add(testData);
            context.SaveChanges();
            context.Entry(testData).State = EntityState.Detached;

            var updatedData = new MyData()
            {
                MyDataId = testData.MyDataId,
                Title = newTitle,
                Description = testData.Description,
                IsEnabled = testData.IsEnabled,
                RowVersion = testData.RowVersion,
                TimeStampUtc = testData.TimeStampUtc
            };

            IActionResult res = await controller.UpdateData(updatedData.MyDataId, updatedData);

            MyData fromDatabase = context.MyData.Find(updatedData.MyDataId);

            Assert.NotEqual(testData.Title, newTitle);
            Assert.Equal(updatedData.Title, newTitle);
            Assert.Equal(fromDatabase.Title, newTitle);
        }

        [Theory, AutoData_SqlMem]
        public async Task UpdateData_When_Doesnt_Exists_Returns_Error([Frozen] MyDataContext context, MyDataController controller, MyData testData)
        {
            MyData existing = context.MyData.Find(testData.MyDataId);
            if (existing != null)
            {
                context.MyData.Remove(existing);
                context.SaveChanges();
                context.Entry(existing).State = EntityState.Detached;
            }

            IActionResult res = await controller.UpdateData(testData.MyDataId, testData);
            Assert.IsAssignableFrom<NotFoundResult>(res);
        }

        [Theory, AutoData_SqlMem]
        public async Task UpdateData_When_ID_Doesnt_Match_Returns_Error(MyDataController controller, MyData testData)
        {
            IActionResult res = await controller.UpdateData(testData.MyDataId++, testData);
            Assert.IsAssignableFrom<BadRequestObjectResult>(res);
        }


        [Theory, AutoData_SqlMem]
        public async Task Delete_Should_Remove_Item([Frozen] MyDataContext context, MyDataController controller, MyData testData)
        {
            //Add the test data to the database and then detach it
            testData.MyDataId = 0;
            context.MyData.Add(testData);
            context.SaveChanges();
            context.Entry(testData).State = EntityState.Detached;


            IActionResult res = await controller.Delete(testData.MyDataId);

            MyData fromDatabase = context.MyData.Find(testData.MyDataId);

            Assert.Null(fromDatabase);
        }


        [Theory, AutoData_SqlMem]
        public async Task Delete_When_Doesnt_Exists_Returns_Error([Frozen] MyDataContext context, MyDataController controller, MyData testData)
        {
            MyData existing = context.MyData.Find(testData.MyDataId);
            if (existing != null)
            {
                context.MyData.Remove(existing);
                context.SaveChanges();
                context.Entry(existing).State = EntityState.Detached;
            }

            IActionResult res = await controller.Delete(testData.MyDataId);
            Assert.IsAssignableFrom<NotFoundResult>(res);
        }
    }
}
