      
module InputData
    
    type InputVariablesData
    
        real :: Ma                      ! Mach number
        real :: xmax                    ! Maximum horizontal displacement of Control Nodes
        real :: ymax                    ! Maximum vertical displacement of Control Nodes
        real :: zmax                    ! Maximum lateral displacement of Control Nodes
        real :: gamma                   ! Ratio of specific heats
        real :: R                       ! specific gas constant
        real :: Tamb					! ambient Temperature [K]
        real :: Pamb    				! ambient Pressure [Pa]
        real :: engFMF                  ! Solver variable - engines Front Mass Flow
        real :: Top2Low                 ! Fraction of Top to Low Nests
        integer :: NoNests              ! Number of Nests (Cuckoo Search)
        integer :: NoSnap               ! Number of initial Snapshots
        integer :: NoCP                 ! Number of Control Points
        integer :: NoDim                ! Number of Dimensions
        integer :: NoG                  ! Number of Generations
        integer :: NoPOMod              ! No of POD Modes considered
        integer :: NoLeviSteps          ! Number of Levy walks per movement
        integer :: NoIter               ! Batch File variable - Number of Iterations    
        logical :: constrain            ! Constrain: Include boundaries of design space for Levy Walk - 1:Yes 0:no
        integer :: delay                ! Delay per check in seconds
        integer :: waitMax              ! maximum waiting time in hours
        real :: Aconst                  ! Levy Flight parameter (determined emperically) 
    
        character(len=20) :: filename    ! I/O file of initial Meshes for FLITE solver
        character :: runOnCluster       ! Run On Cluster or Run on Engine?
        character :: SystemType         ! Windows('W'), Cluster/QSUB ('Q') or HPCWales/BSUB ('B') System? (Cluster, HPCWales = Linux, Visual Studio = Windows)    
        character(len=20) :: UserName    ! Putty Username
        character(len=20) :: Password    ! Putty Password
        character(len=100) :: defPath    ! defines defaultpath - Clusterpath: 'egnaumann/2DEngInlSim/'
        character(len=3) :: version
    
    end type InputVariablesData
    
    type(InputVariablesData) :: IV
    integer :: i, j, k                                          ! Simple Loop Variables
    integer :: allocatestatus                                   ! Check Allocation Status for Large Arrays
    character(len=10) :: InFolder = 'Input_Data'                ! Input Folder Name
    character(len=11) :: OutFolder = 'Output_Data'              ! Output Folder Name
    integer :: IntSystem                                        ! Length of System command string; used for character variable allocation
    real :: waitTime                                            ! waiting time for Simulation Results
    integer :: jobcheck                                         ! Check Variable for Simulation 
    character(len=:), allocatable :: istr                       ! Number of I/O file
    character(len=21) :: pathWin                                ! Path to Windows preprocessor file
    character(len=:), allocatable :: pathLin_Prepro             ! Path to Linux preprocessor file
    character(len=:), allocatable :: pathLin_Solver             ! Path to Linux Solver file
    character(len=:), allocatable :: strSystem                  ! System Command string for communication with FLITE Solver
    character(len=8) :: date                                    ! Container for current date
    character(len=10) :: time                                   ! Container for current time
    character(len=35) :: newdir                                 ! Name of new folder for a new Solution generated by 2D solver
    
contains
    
    subroutine SubInputData(IV)
    
        ! Variables
        implicit none
        type(InputVariablesData) :: IV
    
        ! Body of SubInputData
        namelist /InputVariables/ IV
    
        IV%Ma = 0.5  		            ! Mach number
        IV%Tamb = 30					! ambient Temperature [deg]
        IV%Pamb = 101325				! ambient Pressure [Pa]
        IV%R = 287                  	! specific gas constant
        IV%gamma = 1.4                  ! Ratio of specific heats
        IV%xmax = 0.00			        ! Maximum horizontal displacement of Control Nodes    
        IV%ymax = 0.02			        ! Maximum vertical displacement of Control Nodes    
        IV%zmax = 0.00			        ! Maximum lateral displacement of Control Nodes    
        IV%engFMF = 1.0			        ! engines Front Mass Flow(Solver variable)
        IV%Top2Low = 0.75		        ! Fraction of Top to Low Cuckoo Nests
        IV%NoSnap = 1000                ! Number of initial Snapshots
        IV%NoCP = 7			            ! Number of Control Points 
        IV%NoDim = 2			        ! Number of Dimensions in Space 
        IV%NoG = 100		            ! Number of Generations
        IV%NoNests = 10*IV%NoDim*IV%NoCP! Number of Nests (Cuckoo Search)
        IV%NoPOMod = -1			        ! No of POD Modes considered 
        IV%NoLeviSteps = 100         	! Number of Levy walks per movement 
        IV%NoIter = -3               	! Batch File variable - Number of Iterations 
        IV%constrain = .TRUE.         	! Constrain: Include boundaries of design space for Levy Walk - 1:Yes 0:no
        IV%delay = 300               	! Sleep Time between check for Simulation Results in seconds
        IV%waitMax = 48			        ! maximum waiting time in hours
        IV%Aconst = 0.01		        ! Levy Flight parameter (determined emperically)
        IV%filename = 'Snapshot'        ! I/O file of initial Meshes for FLITE solver
        IV%runOnCluster = 'Y'           ! Run On Cluster or Run on Engine?
        IV%SystemType = 'Q'             ! Windows('W'), Cluster/QSUB ('Q') or HPCWales/BSUB ('B') System? (Cluster, HPCWales = Linux, Visual Studio = Windows)
        IV%UserName = 'egnaumann'       ! Putty Username
        IV%Password = 'Fleur666'        ! Putty Password
        IV%defPath = 'egnaumann/2DEngInlSim'  ! defines defaultpath - Clusterpath: 'egnaumann/2DEngInlSim/'
        IV%version = '1.6'
    
        open(1,file = InFolder//'/AerOpt_InputParameters.txt')
        read(1,InputVariables)
        close(1)
        
    end subroutine SubInputData
    
end module InputData