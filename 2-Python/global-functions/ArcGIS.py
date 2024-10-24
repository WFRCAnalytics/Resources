###############################################################################
'''
 This script contains various functions for geoprocessing that 
 use either the arcpy or arcgis python api libraries
'''
###############################################################################


def fill_na_sedf(df_with_shape_column, fill_value=0):
    '''
    fill NA values in Spatially enabled dataframes (ignores SHAPE column)
    '''
    
    import pandas as pd
    
    if 'SHAPE' in list(df_with_shape_column.columns):
        df = df_with_shape_column.copy()
        shape_column = df['SHAPE'].copy()
        del df['SHAPE']
        return df.fillna(fill_value).merge(shape_column,left_index=True, right_index=True, how='inner')
    else:
        raise Exception("Dataframe does not include 'SHAPE' column")
    
def aportion_polygon_arcpy(_data, _dest, _fields, _out):
    '''
    works the same as the apportion polygon tool included with arcgis pro
    data: string-polygons with numerical data
    dest: string-destination polygons to apportion to
    fields: list-list of numerical fields
    out: string-output file name
    '''
    
    # setup environment
    import arcpy
    import os
    outputs = '.\\Outputs'
    if not os.path.exists(outputs): os.makedirs(outputs) 

    # ensure inputs are polygon
    for dataset in [_data, _dest]:
        if arcpy.Describe(dataset).shapeType != 'Polygon':
            raise Exception(f"""Input dataset:{dataset} must be of geometry type:'Polygon'""")

    # ensure _fields are int, float, or double
    field_objects = [field for field in arcpy.ListFields(_data) if field.name in _fields]
    for  field in field_objects:
        if  field.type not in ['SmallInteger','Integer', 'BigInteger', 'Double', 'Single', 'Double']:
            raise Exception(f'Field:{field.name} is not an accepted numeric type')
        
    # copy inputs, add a temporary id to the destination features, add area to the data features
    data_copy = arcpy.CopyFeatures_management(_data, os.path.join(outputs, '_00_temp_data_copy.shp'))
    dest_copy = arcpy.CopyFeatures_management(_dest, os.path.join(outputs, '_01_temp_dest_copy.shp'))

    dest_id = "dest_id"
    expression = "autoIncrement()"
    
    codeblock = '''
rec=0 
def autoIncrement(): 
    global rec 
    pStart = 1  
    pInterval = 1 
    if (rec == 0):  
        rec = pStart  
    else:  
        rec += pInterval  
    return rec'''

    arcpy.management.CalculateField(dest_copy, dest_id, expression, "PYTHON3", codeblock)

    data_area_attribute = "area_data"
    arcpy.AddField_management(data_copy, field_name=data_area_attribute, field_type='float')
    with arcpy.da.UpdateCursor(data_copy, [data_area_attribute, 'SHAPE@AREA']) as cursor:
        for row in cursor:
            row[0] = row[1]
            cursor.updateRow(row)

    # create overlay of all features and calculate percentage of area of original features
    identity = arcpy.analysis.Identity(data_copy, dest_copy, os.path.join(outputs, '_02_temp_identity.shp'))
    dest_area_attribute = "area_dest"
    arcpy.AddField_management(identity, field_name=dest_area_attribute, field_type='float')
    with arcpy.da.UpdateCursor(identity, [dest_area_attribute, 'SHAPE@AREA']) as cursor:
        for row in cursor:
            row[0] = row[1]
            cursor.updateRow(row)

    area_percent_attribute = 'area_pct'
    arcpy.AddField_management(identity, field_name=area_percent_attribute, field_type='float')
    arcpy.management.CalculateField(identity, area_percent_attribute, 
                                    f'!{dest_area_attribute}!/!{data_area_attribute}!', "PYTHON3")
    
    # dissolve back into the original destination features getting the sum of the input fields
    for field in _fields: arcpy.management.CalculateField(identity, field, f'!{field}!*!{area_percent_attribute}!', "PYTHON3")
    identity_lyr = arcpy.SelectLayerByAttribute_management(identity, "NEW_SELECTION", f'''({dest_id} IS NOT NULL And {dest_id} <> ' ')''')
    statistics_fields = [[field, 'SUM'] for field in _fields]
    dissolved = arcpy.management.Dissolve(identity_lyr, _out, dest_id, statistics_fields, "MULTI_PART", "DISSOLVE_LINES")

    # recreate the original field names, remove arcpy generated field names
    dissolved_field_names = [field.name for field in arcpy.ListFields(dissolved)]
    arcpy_stat_field_names = [field for field in dissolved_field_names if field not in [dest_id ,'FID', 'Shape', 'Shape_Length', 'Shape_Area', 'OBJECTID']]
    for arcpy_field_name, real_field_name in zip(arcpy_stat_field_names, _fields):
        arcpy.AddField_management(dissolved, field_name=real_field_name, field_type='float')
        arcpy.management.CalculateField(dissolved, real_field_name, f'!{arcpy_field_name}!', "PYTHON3")
    arcpy.management.DeleteField(dissolved, arcpy_stat_field_names + [dest_id], 'DELETE_FIELDS')
                
    # clean-up
    for dataset in [data_copy, dest_copy, identity]:
        arcpy.management.Delete(dataset)

    return(_out)
        
        
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