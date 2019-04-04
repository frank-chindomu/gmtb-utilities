#!/bin/ksh

##########################################################################
#
# Script Name: run_metplus.ksh
#
# Description: 
# This script...
#
# START_TIME = The cycle time to use for the initial time.
# 
##########################################################################

# Make sure we give other group members write access to the files we create
umask 002

MKDIR=/bin/mkdir
ECHO=/bin/echo
CUT=`which cut`
DATE=/bin/date
    
source /apps/lmod/lmod/init/sh
module purge
module load contrib
module load anaconda
module use /lfs1/projects/dtc-hurr/MET/MET_releases/modulefiles
module load met/8.0
module load nco
module load wgrib2

export METPLUS_PATH=/mnt/lfs3/projects/hfv3gfs/GMTB/met_workflow/METplus/METplus-2.0.4
export MET_PATH=/mnt/lfs1/projects/dtc-hurr/MET/MET_releases/8.0
export JLOGFILE=/mnt/lfs3/projects/hfv3gfs/GMTB/met_workflow/METplus/logs/metplus_jlogfile
export PYTHONPATH=${METPLUS_PATH}/ush:${METPLUS_PATH}/parm
export PATH=${PATH}:${METPLUS_PATH}/ush:.

# Vars used for manual testing of the script
#export PROJ_DIR=/mnt/lfs3/projects/hfv3gfs/GMTB
#export OUTPUT_BASE=${PROJ_DIR}/METVX
#export TMP_DIR=${OUTPUT_BASE}/tmp
#export METPLUS_CONFIG_DIR=${PROJ_DIR}/met_workflow/config/metplus
#export SUITE='suite1' # suite1-4
#export INIT_BEG='2016010100' # Start time YYYYMMDDHH
#export INIT_END=${INIT_BEG} # End time YYYYMMDDHH
#export FCST_INIT_INTERVAL='6'
#export FCST_MAX_FORECAST='240'
#export LEAD_SEQ='24,48,72,96,120,144,168,192,216,240' # Forecast hours of interest for 12Z initializations
#export LEAD_SEQ='36,60,84,108,132,156,180,204,228' # Forecast hours of interest for 00Z initializations
#export FCST_VAR1_NAME='APCP' # Variables of interest
#export FCST_VAR1_LEVELS='A24' # Levels or accumulation time of interest e.g., Z10, A06
#export OBS_VAR1_NAME='cmorph_precip5' # Variables of interest
#export OBS_VAR1_LEVELS='"(*,*)"' # Levels or accumulation time of interest e.g., Z10, A06
#export RES='0p25'
#export GRID_VX='FCST'
#export FCST_GRID_STAT_INPUT_DIR=${PROJ_DIR}/Phys_Test_FV3GFSv2/POST/${SUITE}
#export OBS_GRID_STAT_INPUT_DIR=${PROJ_DIR}/vx_data/cmorph/cmorph_v0.x/0.25deg_24h
#export FCST_PCP_COMBINE_OUTPUT_DIR=${OUTPUT_BASE}/${INIT_BEG}/${SUITE}/${INIT_BEG}00/grid_stat/pcp_combine

# Print run paramenters
${ECHO}
${ECHO} "run_metplus.ksh started at `${DATE}`"
${ECHO}
${ECHO} "    PROJ_DIR                   = ${PROJ_DIR}"
${ECHO} "    OUTPUT_BASE                = ${OUTPUT_BASE}"
${ECHO} "    TMP_DIR                    = ${TMP_DIR}"
${ECHO} "    MET_INSTALL_DIR            = ${MET_PATH}"
${ECHO} "    METPLUS_CONFIG_DIR         = ${METPLUS_CONFIG_DIR}"
${ECHO} "    SUITE                      = ${SUITE}"
${ECHO} "    INIT_BEG                   = ${INIT_BEG}"
${ECHO} "    INIT_END                   = ${INIT_END}"
${ECHO} "    FCST_INIT_INTERVAL         = ${FCST_INIT_INTERVAL}"
${ECHO} "    FCST_MAX_FORECAST          = ${FCST_MAX_FORECAST}"
${ECHO} "    LEAD_SEQ                   = ${LEAD_SEQ}"
${ECHO} "    FCST_VAR1_NAME             = ${FCST_VAR1_NAME}"
${ECHO} "    FCST_VAR1_LEVELS           = ${FCST_VAR1_LEVELS}"
${ECHO} "    OBS_VAR1_NAME             = ${OBS_VAR1_NAME}"
${ECHO} "    OBS_VAR1_LEVELS           = ${OBS_VAR1_LEVELS}"
${ECHO} "    RES                        = ${RES}"
${ECHO} "    GRID_VX                    = ${GRID_VX}"
${ECHO} "    FCST_GRID_STAT_INPUT_DIR   = ${FCST_GRID_STAT_INPUT_DIR}"
${ECHO} "    OBS_GRID_STAT_INPUT_DIR    = ${OBS_GRID_STAT_INPUT_DIR}"

# Check for exisitance of post files?

# Go to working directory
workdir=${OUTPUT_BASE}/${INIT_BEG}/${SUITE}
${MKDIR} -p ${workdir}
${MKDIR} -p ${workdir}/config
cd ${workdir}

# Config file for grid_stat
APCP_CONFIG=apcp_24_gmtb.conf

# Update METplus config file with information
cat ${METPLUS_CONFIG_DIR}/${APCP_CONFIG}.IN | sed s:_PROJ_DIR_:${PROJ_DIR}:g      \
                         | sed s:_METPLUS_PATH_:${METPLUS_PATH}:g                 \
                         | sed s:_OUTPUT_BASE_:${workdir}:g                       \
                         | sed s:_MET_INSTALL_DIR_:${MET_PATH}:g                  \
                         | sed s:_TMP_DIR_:${TMP_DIR}:g                           \
                         | sed s:_FCST_PCP_COMBINE_OUTPUT_DIR_:${FCST_PCP_COMBINE_OUTPUT_DIR}:g \
                         | sed s:_FCST_GRID_STAT_INPUT_DIR_:${FCST_GRID_STAT_INPUT_DIR}:g \
                         | sed s:_OBS_GRID_STAT_INPUT_DIR_:${OBS_GRID_STAT_INPUT_DIR}:g   \
                         | sed s:_INIT_BEG_:${INIT_BEG}:g                         \
                         | sed s:_INIT_END_:${INIT_BEG}:g                         \
                         | sed s:_LEAD_SEQ_:${LEAD_SEQ}:g                         \
                         | sed s:_FCST_VAR1_NAME_:${FCST_VAR1_NAME}:g             \
                         | sed s:_FCST_VAR1_LEVELS_:${FCST_VAR1_LEVELS}:g         \
                         | sed s:_OBS_VAR1_NAME_:${OBS_VAR1_NAME}:g             \
                         | sed s:_OBS_VAR1_LEVELS_:${OBS_VAR1_LEVELS}:g           \
                         | sed s:_FCST_MAX_FORECAST_:${FCST_MAX_FORECAST}:g       \
                         | sed s:_FCST_INIT_INTERVAL_:${FCST_INIT_INTERVAL}:g     \
                         | sed s:_RES_:${RES}:g                                   \
                         | sed s:_GRID_VX_:${GRID_VX}:g                           \
                         | sed s:_SUITE_:${SUITE}:g                  > ${workdir}/config/${APCP_CONFIG}


${METPLUS_PATH}/ush/master_metplus.py -c ${workdir}/config/${APCP_CONFIG}

error=$?
if [ ${error} -ne 0 ]; then
    ${ECHO} "ERROR: run_metplus_global.ksh crashed for ${SUITE}. Exit status: ${error}"
    exit ${error}
fi

##########################################################################

${ECHO} "run_metplus_global.ksh completed at `${DATE}`"

exit 0
