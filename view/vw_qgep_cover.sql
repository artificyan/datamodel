﻿-- View: vw_qgep_cover

--- 27.4.2016 Changed detail_geometry_3d_geometry to detail_geometry3d_geometry - adaption to new datamodel 20160426

BEGIN TRANSACTION;

DROP VIEW IF EXISTS qgep.vw_qgep_cover;

CREATE OR REPLACE VIEW qgep.vw_qgep_cover AS
 SELECT ws.obj_id,
    co.brand,
    co.cover_shape,
    co.diameter,
    co.fastening,
    co.level,
    co.material AS cover_material,
    co.positional_accuracy,
    co.situation_geometry,
    co.sludge_bucket,
    co.venting,
    co.identifier AS co_identifier,
    co.remark,
    co.renovation_demand,
    co.last_modification,
    co.fk_dataowner,
    co.fk_provider,

    CASE
      WHEN mh.obj_id IS NOT NULL THEN 'manhole'
      WHEN ss.obj_id IS NOT NULL THEN 'special_structure'
      WHEN dp.obj_id IS NOT NULL THEN 'discharge_point'
      WHEN ii.obj_id IS NOT NULL THEN 'infiltration_installation'
      ELSE 'unknown'
    END AS ws_type,

    co.obj_id as co_obj_id,
    ws.identifier as identifier,
    ws.accessibility,
    ws.contract_section,
    ws.financing,
    ws.gross_costs,
    ws.inspection_interval,
    ws.location_name,
    ws.records,
    ws.remark AS ws_remark,
    ws.renovation_necessity,
    ws.replacement_value,
    ws.rv_base_year,
    ws.rv_construction_type,
    ws.status,
    ws.structure_condition,
    ws.subsidies,
    ws.year_of_construction,
    ws.year_of_replacement,
    ws.fk_owner,
    ws.fk_operator,
    ws._label,

    COALESCE( mh.depth, ss.depth, dp.depth, ii.depth ) AS depth,
    COALESCE( mh.dimension1, ii.dimension1 ) AS dimension1,
    COALESCE( mh.dimension2, ii.dimension2 ) AS dimension2,
    COALESCE( ss.upper_elevation, dp.upper_elevation, ii.upper_elevation ) AS upper_elevation,

    mh.function AS manhole_function,
    mh.material,
    mh.surface_inflow,

    ws._usage_current AS channel_usage_current,
    ws._function_hierarchic AS channel_function_hierarchic,
    mh._orientation AS manhole_orientation,

    ss.bypass,
    ss.function as special_structure_function,
    ss.stormwater_tank_arrangement,

    dp.highwater_level,
    dp.relevance,
    dp.terrain_level,
    dp.waterlevel_hydraulic,

    ii.absorption_capacity,
    ii.defects,
    ii.distance_to_aquifer,
    ii.effective_area,
    ii.emergency_spillway,
    ii.kind,
    ii.labeling,
    ii.seepage_utilization,
    ii.vehicle_access,
    ii.watertightness,

    wn.obj_id AS wn_obj_id,
    wn.backflow_level,
    wn.bottom_level,
    -- wn.situation_geometry ,
    wn.identifier AS wn_identifier,
    wn.remark AS wn_remark,
    wn.last_modification AS wn_last_modification,
    wn.fk_dataowner AS wn_fk_dataowner,
    wn.fk_provider AS wn_fk_provider

   FROM qgep.vw_cover co
     LEFT JOIN qgep.od_wastewater_structure ws ON ws.obj_id = co.fk_wastewater_structure
     LEFT JOIN qgep.od_manhole mh ON mh.obj_id = co.fk_wastewater_structure
     LEFT JOIN qgep.od_special_structure ss ON ss.obj_id = co.fk_wastewater_structure
     LEFT JOIN qgep.od_discharge_point dp ON dp.obj_id = co.fk_wastewater_structure
     LEFT JOIN qgep.od_infiltration_installation ii ON ii.obj_id = co.fk_wastewater_structure

     LEFT JOIN qgep.vw_wastewater_node wn ON wn.fk_wastewater_structure = ws.obj_id;

-- INSERT function

CREATE OR REPLACE FUNCTION qgep.vw_qgep_cover_INSERT()
  RETURNS trigger AS
$BODY$
BEGIN

  NEW.identifier = COALESCE(NEW.identifier, NEW.obj_id);

  INSERT INTO qgep.od_wastewater_structure(
      obj_id
    , accessibility
    , contract_section
    , financing
    , gross_costs
    , identifier
    , inspection_interval
    , location_name
    , records
    , remark
    , renovation_necessity
    , replacement_value
    , rv_base_year
    , rv_construction_type
    , status
    , structure_condition
    , subsidies
    , year_of_construction
    , year_of_replacement
    , last_modification
    , fk_dataowner
    , fk_provider
    , fk_owner
    , fk_operator
  )
  VALUES
  (
      NEW.obj_id
    , NEW.accessibility
    , NEW.contract_section
    , NEW.financing
    , NEW.gross_costs
    , NEW.identifier
    , NEW.inspection_interval
    , NEW.location_name
    , NEW.records
    , NEW.remark
    , NEW.renovation_necessity
    , NEW.replacement_value
    , NEW.rv_base_year
    , NEW.rv_construction_type
    , NEW.status
    , NEW.structure_condition
    , NEW.subsidies
    , NEW.year_of_construction
    , NEW.year_of_replacement
    , NEW.last_modification
    , NEW.fk_dataowner
    , NEW.fk_provider
    , NEW.fk_owner
    , NEW.fk_operator
  );

  -- Manhole
  CASE
    WHEN NEW.ws_type = 'manhole' THEN
      INSERT INTO qgep.od_manhole(
             obj_id
           , dimension1
           , dimension2
           , depth
           , function
           , material
           , surface_inflow
           )
           VALUES
           (
             NEW.obj_id
           , NEW.dimension1
           , NEW.dimension2
           , NEW.depth
           , NEW.manhole_function
           , NEW.material
           , NEW.surface_inflow
           );

    -- Special Structure
    WHEN NEW.ws_type = 'special_structure' THEN
      INSERT INTO qgep.od_special_structure(
             obj_id
           , depth
           , emergency_spillway
           , function
           , stormwater_tank_arrangement
           , upper_elevation
           )
           VALUES
           (
             NEW.obj_id
           , NEW.depth
           , NEW.emergency_spillway
           , NEW.special_structure_function
           , NEW.stormwater_tank_arrangement
           , NEW.upper_elevation
           );

    -- Discharge Point
    WHEN NEW.ws_type = 'discharge_point' THEN
      INSERT INTO qgep.od_discharge_point(
             obj_id
           , depth
           , highwater_level
           , relevance
           , terrain_level
           , upper_elevation
           , waterlevel_hydraulic
           )
           VALUES
           (
             NEW.obj_id
           , NEW.depth
           , NEW.highwater_level
           , NEW.relevance
           , NEW.terrain_level
           , NEW.upper_elevation
           , NEW.waterlevel_hydraulic
           );

    -- Infiltration Installation
    WHEN NEW.ws_type = 'infiltration_installation' THEN
      INSERT INTO qgep.od_infiltration_installation(
             obj_id
           , absorption_capacity
           , defects
           , depth
           , dimension1
           , dimension2
           , distance_to_aquifer
           , effective_area
           , emergency_spillway
           , kind
           , labeling
           , seepage_utilization
           , upper_elevation
           , vehicle_access
           , watertightness
           )
           VALUES
           (
             NEW.obj_id
           , NEW.absorption_capacity
           , NEW.defects
           , NEW.depth
           , NEW.dimension1
           , NEW.dimension2
           , NEW.distance_to_aquifer
           , NEW.effective_area
           , NEW.emergency_spillway
           , NEW.kind
           , NEW.labeling
           , NEW.seepage_utilization
           , NEW.upper_elevation
           , NEW.vehicle_access
           , NEW.watertightness
           );
    ELSE
     RAISE NOTICE 'Wastewater structure type not known (%)', ws_type; -- ERROR
  END CASE;

  INSERT INTO qgep.vw_wastewater_node(
      obj_id
    , backflow_level
    , bottom_level
    , situation_geometry
    , identifier
    , remark
    , last_modification
    , fk_dataowner
    , fk_provider
    , fk_wastewater_structure
  )
  VALUES
  (
      NEW.wn_obj_id
    , NEW.backflow_level
    , NEW.bottom_level
    , NEW.situation_geometry
    , COALESCE(NULLIF(NEW.wn_identifier,''), NEW.identifier)
    , NEW.wn_remark
    , NOW()
    , COALESCE(NULLIF(NEW.wn_fk_provider,''), NEW.fk_provider)
    , COALESCE(NULLIF(NEW.wn_fk_dataowner,''), NEW.fk_dataowner)
    , NEW.obj_id
  );

  INSERT INTO qgep.vw_cover(
      obj_id
    , brand
    , cover_shape
    , diameter
    , fastening
    , level
    , material
    , positional_accuracy
    , situation_geometry
    , sludge_bucket
    , venting
    , identifier
    , remark
    , renovation_demand
    , last_modification
    , fk_dataowner
    , fk_provider
    , fk_wastewater_structure
  )
  VALUES
  (
      NEW.co_obj_id
    , NEW.brand
    , NEW.cover_shape
    , NEW.diameter
    , NEW.fastening
    , NEW.level
    , NEW.cover_material
    , NEW.positional_accuracy
    , NEW.situation_geometry
    , NEW.sludge_bucket
    , NEW.venting
    , COALESCE(NULLIF(NEW.co_identifier,''), NEW.identifier)
    , NEW.remark
    , NEW.renovation_demand
    , NOW()
    , NEW.fk_dataowner
    , NEW.fk_provider
    , NEW.obj_id
  );
  RETURN NEW;
END; $BODY$ LANGUAGE plpgsql VOLATILE;

DROP TRIGGER IF EXISTS vw_qgep_cover_ON_INSERT ON qgep.vw_qgep_cover;

CREATE TRIGGER vw_qgep_cover_ON_INSERT INSTEAD OF INSERT ON qgep.vw_qgep_cover
  FOR EACH ROW EXECUTE PROCEDURE qgep.vw_qgep_cover_INSERT();

/**************************************************************
 * UPDATE
 *************************************************************/
CREATE OR REPLACE FUNCTION qgep.vw_qgep_cover_UPDATE()
  RETURNS trigger AS
$BODY$
DECLARE
BEGIN
    UPDATE qgep.od_cover
      SET
        brand = NEW.brand,
        cover_shape = new.cover_shape,
        depth = new.depth,
        diameter = new.diameter,
        fastening = new.fastening,
        level = new.level,
        material = new.cover_material,
        positional_accuracy = new.positional_accuracy,
        situation_geometry = new.situation_geometry,
        sludge_bucket = new.sludge_bucket,
        venting = new.venting
    WHERE od_cover.obj_id::text = old.co_obj_id::text;

    UPDATE qgep.od_structure_part
      SET
        identifier = new.co_identifier,
        remark = new.remark,
        renovation_demand = new.renovation_demand,
        last_modification = new.last_modification,
        fk_dataowner = new.fk_dataowner,
        fk_provider = new.fk_provider
    WHERE od_structure_part.obj_id::text = old.obj_id::text;

    UPDATE qgep.od_wastewater_structure
      SET
        obj_id = NEW.obj_id,
        identifier = NEW.identifier,
        accessibility = NEW.accessibility,
        contract_section = NEW.contract_section,
        financing = NEW.financing,
        gross_costs = NEW.gross_costs,
        inspection_interval = NEW.inspection_interval,
        location_name = NEW.location_name,
        records = NEW.records,
        remark = NEW.ws_remark,
        renovation_necessity = NEW.renovation_necessity,
        replacement_value = NEW.replacement_value,
        rv_base_year = NEW.rv_base_year,
        rv_construction_type = NEW.rv_construction_type,
        status = NEW.status,
        structure_condition = NEW.structure_condition,
        subsidies = NEW.subsidies,
        year_of_construction = NEW.year_of_construction,
        year_of_replacement = NEW.year_of_replacement,
        fk_owner = NEW.fk_owner,
        fk_operator = NEW.fk_operator
     WHERE od_wastewater_structure.obj_id::text = old.obj_id::text;

  IF OLD.ws_type <> NEW.ws_type THEN
    CASE
      WHEN OLD.ws_type = 'manhole' THEN DELETE FROM qgep.od_manhole WHERE obj_id = OLD.obj_id;
      WHEN OLD.ws_type = 'special_structure' THEN DELETE FROM qgep.od_special_structure WHERE obj_id = OLD.obj_id;
      WHEN OLD.ws_type = 'discharge_point' THEN DELETE FROM qgep.od_discharge_point WHERE obj_id = OLD.obj_id;
      WHEN OLD.ws_type = 'infiltration_installation' THEN DELETE FROM qgep.od_infiltration_installation WHERE obj_id = OLD.obj_id;
    END CASE;

    CASE
      WHEN NEW.ws_type = 'manhole' THEN INSERT INTO qgep.od_manhole (obj_id) VALUES(OLD.obj_id);
      WHEN NEW.ws_type = 'special_structure' THEN INSERT INTO qgep.od_special_structure (obj_id) VALUES(OLD.obj_id);
      WHEN NEW.ws_type = 'discharge_point' THEN INSERT INTO qgep.od_discharge_point (obj_id) VALUES(OLD.obj_id);
      WHEN NEW.ws_type = 'infiltration_installation' THEN INSERT INTO qgep.od_infiltration_installation (obj_id) VALUES(OLD.obj_id);
    END CASE;
  END IF;

  CASE
    WHEN NEW.ws_type = 'manhole' THEN
      UPDATE qgep.od_manhole
      SET
        depth = NEW.depth,
        dimension1 = NEW.dimension1,
        dimension2 = NEW.dimension2,
        function = NEW.manhole_function,
        material = NEW.material,
        surface_inflow = NEW.surface_inflow
      WHERE obj_id = OLD.obj_id;

    WHEN NEW.ws_type = 'special_structure' THEN
      UPDATE qgep.od_special_structure
      SET
        bypass = NEW.bypass,
        depth = NEW.depth,
        emergency_spillway = NEW.emergency_spillway,
        function = NEW.special_structure_function,
        stormwater_tank_arrangement = NEW.stormwater_tank_arrangement,
        upper_elevation = NEW.upper_elevation
      WHERE obj_id = OLD.obj_id;

    WHEN NEW.ws_type = 'discharge_point' THEN
      UPDATE qgep.od_discharge_point
      SET
        depth = NEW.depth,
        highwater_level = NEW.highwater_level,
        relevance = NEW.relevance,
        terrain_level = NEW.terrain_level,
        upper_elevation = NEW.upper_elevation,
        waterlevel_hydraulic = NEW.waterlevel_hydraulic
      WHERE obj_id = OLD.obj_id;

    WHEN NEW.ws_type = 'infiltration_installation' THEN
      UPDATE qgep.od_infiltration_installation
      SET
        absorption_capacity = NEW.absorption_capacity,
        defects = NEW.defects,
        depth = NEW.depth,
        dimension1 = NEW.dimension1,
        dimension2 = NEW.dimension2,
        distance_to_aquifer = NEW.distance_to_aquifer,
        effective_area = NEW.effective_area,
        emergency_spillway = NEW.emergency_spillway,
        kind = NEW.kind,
        labeling = NEW.labeling,
        seepage_utilization = NEW.seepage_utilization,
        upper_elevation = NEW.upper_elevation,
        vehicle_access = NEW.vehicle_access,
        watertightness = NEW.watertightness
      WHERE obj_id = OLD.obj_id;
  END CASE;

  -- Cover geometry has been moved
  IF NOT ST_Equals( OLD.situation_geometry, NEW.situation_geometry) THEN
    -- Move wastewater node as well
    UPDATE qgep.od_wastewater_node WN
    SET situation_geometry = ST_TRANSLATE(WN.situation_geometry, ST_X(NEW.situation_geometry) - ST_X(OLD.situation_geometry), ST_Y(NEW.situation_geometry) - ST_Y(OLD.situation_geometry ) )
    WHERE obj_id IN 
    (
      SELECT obj_id FROM qgep.od_wastewater_networkelement
      WHERE fk_wastewater_structure = NEW.obj_id
    );

    -- Move reach(es) as well
    UPDATE qgep.od_reach RE
    SET progression_geometry = 
      ST_SetPoint(
        RE.progression_geometry,
        0, -- SetPoint index is 0 based, PointN index is 1 based.
        ST_TRANSLATE(ST_PointN(RE.progression_geometry, 1), ST_X(NEW.situation_geometry) - ST_X(OLD.situation_geometry), ST_Y(NEW.situation_geometry) - ST_Y(OLD.situation_geometry ) )
      )
    WHERE fk_reach_point_from IN 
    (
      SELECT RP.obj_id FROM qgep.od_reach_point RP
      LEFT JOIN qgep.od_wastewater_networkelement NE ON RP.fk_wastewater_networkelement = NE.obj_id
      WHERE NE.fk_wastewater_structure = NEW.obj_id
    );

    UPDATE qgep.od_reach RE
    SET progression_geometry = 
      ST_SetPoint(
        RE.progression_geometry,
        ST_NumPoints(RE.progression_geometry) - 1,
        ST_TRANSLATE(ST_EndPoint(RE.progression_geometry), ST_X(NEW.situation_geometry) - ST_X(OLD.situation_geometry), ST_Y(NEW.situation_geometry) - ST_Y(OLD.situation_geometry ) )
      )
    WHERE fk_reach_point_to IN 
    (
      SELECT RP.obj_id FROM qgep.od_reach_point RP
      LEFT JOIN qgep.od_wastewater_networkelement NE ON RP.fk_wastewater_networkelement = NE.obj_id
      WHERE NE.fk_wastewater_structure = NEW.obj_id
    );
  END IF;

  RETURN NEW;
END; $BODY$ LANGUAGE plpgsql VOLATILE;

DROP TRIGGER IF EXISTS vw_qgep_cover_ON_UPDATE ON qgep.vw_qgep_cover;

CREATE TRIGGER vw_qgep_cover_ON_UPDATE INSTEAD OF UPDATE ON qgep.vw_qgep_cover
  FOR EACH ROW EXECUTE PROCEDURE qgep.vw_qgep_cover_UPDATE();


/**************************************************************
 * DELETE
 *************************************************************/

CREATE OR REPLACE FUNCTION qgep.vw_qgep_cover_DELETE()
  RETURNS trigger AS
$BODY$
DECLARE
BEGIN
  DELETE FROM qgep.od_wastewater_structure WHERE obj_id = OLD.obj_id;
RETURN OLD;
END; $BODY$ LANGUAGE plpgsql VOLATILE;

DROP TRIGGER IF EXISTS vw_qgep_cover_ON_DELETE ON qgep.vw_qgep_cover;

CREATE TRIGGER vw_qgep_cover_ON_DELETE INSTEAD OF DELETE ON qgep.vw_qgep_cover
  FOR EACH ROW EXECUTE PROCEDURE qgep.vw_qgep_cover_DELETE();

/**************************************************************
 * DEFAULT VALUES
 *************************************************************/

ALTER VIEW qgep.vw_qgep_cover ALTER obj_id SET DEFAULT qgep.generate_oid('od_wastewater_structure');



END TRANSACTION;
