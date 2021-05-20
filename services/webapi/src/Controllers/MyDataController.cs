using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

using Webapi.Models;

namespace Webapi.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class MyDataController : ControllerBase
    {
        private readonly ILogger<MyDataController> _logger;
        private readonly MyDataContext _dataContext;

        public MyDataController(MyDataContext dataContext, ILogger<MyDataController> logger)
        {
            this._dataContext = dataContext ?? throw new ArgumentNullException(nameof(dataContext));
            this._logger = logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        [HttpGet]
        [ProducesResponseType(StatusCodes.Status200OK, Type = typeof(IEnumerable<MyData>))]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public IEnumerable<MyData> Get()
        {
            try
            {
                MyData[] returnData = this._dataContext.MyData.Take(10).ToArray();

                this._logger.LogDebug("Found {0} entries", returnData.Length);
                return returnData;
            }
            catch (Exception ex)
            {
                this._logger.LogError(ex, "Problem retrieving MyData");
                throw;
            }
        }

        [HttpGet("{id}")]
        [ProducesResponseType(StatusCodes.Status200OK, Type = typeof(MyData))]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<ActionResult<MyData>> GetById(int id)
        {
            try
            {
                MyData returnData = await this._dataContext.MyData.FindAsync(id);

                if (returnData == null)
                {
                    this._logger.LogDebug("Did not find data with id {0}", id);
                    return this.NotFound();
                }
                else
                {
                    this._logger.LogDebug("Found data with id {0}", id);
                    return returnData;
                }
            }
            catch (Exception ex)
            {
                this._logger.LogError(ex, "Problem retrieving entitye with id {0}", id);
                throw;
            }
        }

        [HttpPost]
        [ProducesResponseType(StatusCodes.Status201Created, Type = typeof(MyData))]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<IActionResult> AddNewData(MyDataContent inputData)
        {
            try
            {
                var myData = new MyData(inputData);

                this._dataContext.Add(myData);
                await this._dataContext.SaveChangesAsync();
                return this.CreatedAtAction(nameof(GetById), new { id = myData.MyDataId }, myData);
            }
            catch (Exception ex)
            {
                this._logger.LogError(ex, "Problem adding data");
                throw;
            }
        }

        [HttpPut("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<IActionResult> UpdateData(int id, MyData inputData)
        {
            try
            {
                if (id != inputData.MyDataId)
                {
                    return this.BadRequest("Id doesn't match");
                }

                MyData existingData = await this._dataContext.MyData.FindAsync(id);
                if (existingData == null)
                {
                    return this.NotFound();
                }

                //Let EF know what the original RowVersion was when data was read before
                //to allow for concurrency check
                this._dataContext.Entry(existingData).Property(p => p.RowVersion).OriginalValue = inputData.RowVersion;

                Microsoft.EntityFrameworkCore.ChangeTracking.EntityEntry<MyData> exitingEntry = this._dataContext.Entry(existingData);
                exitingEntry.Property(p => p.Title).CurrentValue = inputData.Title;
                exitingEntry.Property(p => p.Description).CurrentValue = inputData.Description;
                exitingEntry.Property(p => p.IsEnabled).CurrentValue = inputData.IsEnabled;

                await this._dataContext.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                this._logger.LogError(ex, "Error updating data");

                throw;
            }
            return this.NoContent();
        }

        [HttpDelete("{id}")]
        [ProducesResponseType(StatusCodes.Status204NoContent)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<IActionResult> Delete(int id)
        {
            try
            {
                MyData data = await this._dataContext.MyData.FindAsync(id);
                if (data == null)
                {
                    return this.NotFound();
                }

                this._dataContext.MyData.Remove(data);
                await this._dataContext.SaveChangesAsync();

            }
            catch (Exception ex)
            {
                this._logger.LogError(ex, "Error deleting item with id {0}", id);
                throw;
            }
            return this.NoContent();
        }
    }
}
