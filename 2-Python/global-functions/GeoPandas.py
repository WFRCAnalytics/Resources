###############################################################################
'''
 This script contains various functions for geoprocessing that 
 use the GeoPandas library
'''
###############################################################################


def apportion_polygon_gpd(_data, _dest, _fields, _out, _sig_dig=None, _export=True):
    
    import geopandas as gpd
    
    if not _dest.crs == _data.crs:
        raise Exception(f'The coordinate reference systems do not match; please reproject the dataset(s) and try again')

    for field in _fields:
        field_data_type = _data[field].dtype
        if not pd.api.types.is_numeric_dtype(_data[field]) or field_data_type == 'boolean':
            raise Exception(f'Field:{field} is not an accepted numeric type')

    _dest['dest_id'] = _dest.index
    _data['data_id'] = _data.index
    # _dest['dest_area'] = _dest['geometry'].area
    _data['data_area'] = _data['geometry'].area
    dest_copy = _dest[['dest_id',  'geometry']].copy()
    _data = _data[['data_id', 'data_area', 'geometry'] + _fields].copy()

    identity = data.overlay(dest_copy, how='identity')
    identity['identity_area'] = identity['geometry'].area
    identity['percent_area'] = identity['identity_area'] / identity['data_area']

    for field in _fields:
        identity[field] = identity[field] * identity['percent_area']
        if _sig_dig is not None:
            identity[field] = identity[field].round(_sig_dig)

    agg_fields = {field : "sum" for field in _fields}
    dissolved = identity.dissolve(by='dest_id', aggfunc=agg_fields).reset_index()
    dest_with_values = _dest.merge(dissolved.drop('geometry', axis=1), on='dest_id', how='left')

    for field in _fields:
        dest_with_values[field] = dest_with_values[field].fillna(0)

    if _export == True:
        dest_with_values.to_file(_out)
    
    return dest_with_values