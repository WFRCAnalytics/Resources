###############################################################################
'''
 This script contains various functions for geoprocessing that 
 use either the arcpy or arcgis python api libraries
'''
###############################################################################


# def fill_na_sedf(df_with_shape_column, fill_value=0):
    # '''
    # fill NA values in Spatially enabled dataframes (ignores SHAPE column)
    # '''
    
    
    # import pandas as pd
    
    # if 'SHAPE' in list(df_with_shape_column.columns):
        # df = df_with_shape_column.copy()
        # shape_column = df['SHAPE'].copy()
        # del df['SHAPE']
        # return df.fillna(fill_value).merge(shape_column,left_index=True, right_index=True, how='inner')
    # else:
        # raise Exception("Dataframe does not include 'SHAPE' column")
        
        
# def apportion_polygon(_data, _dest, _fields, _out, _sig_dig=None, _export=True):
    
    # '''
    # apportion values from what polygon dataset to another (draft)
    # '''
    
    
    # from arcgis import GIS
    # from arcgis.features import GeoAccessor
    # from arcgis.features import GeoSeriesAccessor
    
    # if not _dest.crs == _data.crs:
        # raise Exception(f'The coordinate reference systems do not match; please reproject the dataset(s) and try again')

    # for field in _fields:
        # field_data_type = _data[field].dtype
        # if not pd.api.types.is_numeric_dtype(_data[field]) or field_data_type == 'boolean':
            # raise Exception(f'Field:{field} is not an accepted numeric type')

    # _dest['dest_id'] = _dest.index
    # _data['data_id'] = _data.index
    # _data['data_area'] = _data['SHAPE'].area
    # dest_copy = _dest[['dest_id',  'SHAPE']].copy()
    # _data = _data[['data_id', 'data_area', 'SHAPE'] + _fields].copy()

    # # identity = data.overlay(dest_copy, how='identity')
    # identity = data.overlay_layers(dest_copy, overlay_type='Union')
    # identity['identity_area'] = identity['SHAPE'].area
    # identity['percent_area'] = identity['identity_area'] / identity['data_area']

    # for field in _fields:
        # identity[field] = identity[field] * identity['percent_area']
        # if _sig_dig is not None:
            # identity[field] = identity[field].round(_sig_dig)

    # agg_fields = {field : "sum" for field in _fields}
    # dissolved = identity.dissolve(by='dest_id', aggfunc=agg_fields).reset_index()
    # dest_with_values = _dest.merge(dissolved.drop('SHAPE', axis=1), on='dest_id', how='left')

    # for field in _fields:
        # dest_with_values[field] = dest_with_values[field].fillna(0)

    # if _export == True:
        # dest_with_values.to_file(_out)
    
    # return dest_with_values