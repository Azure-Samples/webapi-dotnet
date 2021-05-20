using AutoFixture;
using AutoFixture.AutoNSubstitute;
using AutoFixture.Kernel;
using AutoFixture.Xunit2;

using Microsoft.AspNetCore.Mvc.ModelBinding;

using System;
using System.ComponentModel;

namespace webapi.tests.Utility
{
    /// <summary>
    /// Use this attribute when you want AutoFixture to populate values for both
    /// concrete classes and mocks created with NSubstitute
    /// 
    /// </summary>
    /// <example>
    /// In the code below, auditor will have values created,
    /// IAuditInfo will also have dummy values for every field, 
    /// LoggedinUser will have the empty string value.
    /// 
    /// [Theory, AutoData_NSubstitute_Plus]
    /// public void Sample2(Auditor auditor, IAuditInfo info)
    /// {
    /// 	//This is auto generated.
    /// 	Assert.NotNull(info);
    ///
    /// 	//Members of mocked objects have values.
    /// 	Assert.NotNull(info.ActingUser);
    /// 	Assert.True(info.ActingUser != "");
    /// }
    /// </example>
    public class AutoDataNSubstituteAttribute : AutoDataAttribute
    {
        private readonly bool _skipLiveTest = false;

        public AutoDataNSubstituteAttribute(AutoDataOptions options = AutoDataOptions.Default, params Type[] customizations)
            : base(GetFactory(options, customizations))
        {
            this._skipLiveTest = (options & AutoDataOptions.SkipLiveTest) == AutoDataOptions.SkipLiveTest;
        }

        public AutoDataNSubstituteAttribute(params Type[] customizations) : this(AutoDataOptions.Default, customizations)
        { }

        public override string Skip => LiveUnitTestUtil.SkipIfLiveUnitTest(this._skipLiveTest);

        private static Func<IFixture> GetFactory(AutoDataOptions options, Type[] cusomizations)
        {
            return () =>
            {
                var fixture = new Fixture();

                if (cusomizations != null)
                {
                    foreach (Type customizationType in cusomizations)
                    {
                        if (typeof(ISpecimenBuilder).IsAssignableFrom(customizationType))
                        {
                            var specimentBuilder = Activator.CreateInstance(customizationType) as ISpecimenBuilder;
                            fixture.Customizations.Add(specimentBuilder);
                        }
                        else if (typeof(ICustomization).IsAssignableFrom(customizationType))
                        {
                            var customization = Activator.CreateInstance(customizationType) as ICustomization;
                            fixture.Customize(customization);
                        }
                        else
                        {
                            throw new InvalidEnumArgumentException($"{customizationType.FullName} does not implement ICustomization or ISpecimentBuilder");
                        }
                    }
                }

                fixture.Customize(new AutoNSubstituteCustomization() { ConfigureMembers = (options & AutoDataOptions.SkipMembers) != AutoDataOptions.SkipMembers });

                //This is requried for creating mock Controllers to force BindingInfo values to null
                //othwerwise when assigning BinderType to BindingInfo, it will throw an exception since it does a runtime IModelBinder check
                fixture.Customize(new ConstructorCustomization(typeof(BindingInfo), new GreedyConstructorQuery()));

                return fixture;
            };
        }
    }

    [Flags]
    public enum AutoDataOptions
    {
        SkipMembers = 0x01,
        SkipLiveTest = 0x02,

        Default = 0x00
    }
}