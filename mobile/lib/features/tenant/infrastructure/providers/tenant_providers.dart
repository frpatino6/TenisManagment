/// Export file for tenant providers
/// This file exports all tenant providers that can be used by other features
/// Features should import this file to access tenant functionality through interfaces
export 'tenant_provider_impl.dart' show tenantDataProvider, tenantProviderImplProvider, tenantDataProviderProvider;
export '../adapters/tenant_data_provider_impl.dart' show tenantDataProviderImplProvider;
