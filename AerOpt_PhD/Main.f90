program AerOpt
   
    ! Initializing Parameters and Implement Modules  
    use CreateInitialNests
    use GenerateInitialMeshes
    use Toolbox
    use Optimization
    use ReadData
    
    implicit none
    integer :: i, j, k                ! Simple Loop Variables

    ! ****User Input****** !
    !pathexec2 = '/eng/cvcluster/egmanon/Duct2d'  
    !real, parameter :: Mach = 0.5
    real, parameter :: hMa = 0.5                    ! Mach number
    real, parameter :: xmax = 0.00                  ! Maximum horizontal displacement of Control Nodes
    real, parameter :: ymax = 0.02                  ! Maximum vertical displacement of Control Nodes
    real, parameter :: zmax = 0.00                  ! Maximum lateral displacement of Control Nodes
    real, parameter :: engFMF = 1.0                 ! Batch File variable - engines Front Mass Flow
    real, parameter :: p = 0.75                     ! Fraction of Top to Low Nests
    integer, parameter :: NoNests = 30              ! Number of Nests (Cuckoo Search)
    integer, parameter :: NoCP = 7                  ! Number of Control Points
    integer, parameter :: NoDim = 2                 ! Number of Dimensions
    integer, parameter :: NoG = 5                   ! Number of Generations
    integer, parameter :: NoPOMod = -1              ! No of POD Modes considered
    integer, parameter :: NoLeviSteps = 100         ! Number of Levy walks per movement
    integer, parameter :: NoIter = -3               ! Batch File variable - Number of Iterations    
    logical, parameter :: constrain = 1             ! Constrain: Include boundaries of design space for Levy Walk - 1:Yes 0:no
    real :: Aconst = 0.01                           ! Levy Flight parameter (determined emperically) 
    integer :: PreInt                               ! Length of Linux command string; used for character variable allocation
    integer :: IntSystem                            ! Length of System command string; used for character variable allocation
    ! 1D: only x considered, 2D: x & y considered, 3D: x, y & z considered

    character(len=8), parameter :: filename = 'Snapshot'    ! I/O file of initial Meshes for FLITE solver
    character(len=:), allocatable :: istr                   ! Number of I/O file
    character, parameter :: runOnCluster = 'Y'              ! Run On Cluster or Run on Engine?
    character(len=:), allocatable :: strPrepro              ! System Command string for communication with FLITE Solver
    character(len=:), allocatable :: strSystem              ! System Command string for communication with FLITE Solver
    character, parameter :: IsLin = 'N'                     ! Windows('N') or Linux('Y') System to run on? (Cluster = Linux, Visual Studio = Windows)    
    character(len=51) :: pathLin_Prepro                     ! Path to Linux preprocessor file
    character(len=48) :: pathLin_Solver                     ! Path to Linux Solver file
    character(len=21) :: pathWin                            ! Path to Windows preprocessor file
    character(len=9), parameter :: UserName = 'egnaumann'   ! Putty Username
    character(len=8), parameter :: Password = 'Fleur666'    ! Putty Password
    character(len=8) :: date                                ! Container for current date
    character(len=10) :: time                               ! Container for current time
    character(len=34) :: newdir                             ! Name of new folder for a new Solution generated by 2D solver
    
    ! Check xmax, ymax, zmax & NoDim Input
    select case (NoDim)
    case (1)
        if (ymax /= 0 .or. zmax /= 0) then
            print *, 'ymax and/or zmax remain unconsidered in 1 Dimension'
            print *, 'Input any and click enter to continue'
            read(*, *)
        endif
    case (2)
        if (zmax /= 0) then
            print *, 'zmax remains unconsidered in 2 Dimensions'
            print *, 'Input any and click enter to continue'
            read(*, *)
        endif
    end select
    
    ! Automatically generates a random initial number based on time and date
    call RANDOM_SEED
    
    ! Get Time and Date for File and Folder Name creation
    call DATE_AND_TIME(date, time)
    newdir = '2DEngInletSnapshots_v1_'//date(3:8)//'_'//time(1:4)
    
    ! ****Sub-Section: Create Initial Nests for the CFD Solver****** ! 
    ! ***********included in CreateInitialNests module************** !
    print *, 'Start LHS Sampling - Create Initial Nests'
    call SubCreateInitialNests(NoNests, NoDim, NoCP, xmax, ymax, zmax)                !Sampling of initial points/nests via LHC    
    ! Output: InitialNests - Sampling Points for initial Nests
    
    
    ! ****Read Input Data(Fine Mesh, Coarse Mesh, CP Coordinates, Influence Box/Rectangle (IB)**** !
    print *, 'Start Read Data'
    call SubReadData(NoCP, NoDim)
    ! Output: Boundf, Coord, Connecf, Coord_CP
    
!!!!!! IMPLEMENT double-check, wether Dimension of file and Input are compliant OR error check while Reading files
    
    ! ****Generate initial Meshes/Snapshots**** !
    allocate(coord_temp(np,NoDim))
    allocate(boundff(nbf,(NoDim+1)))
    boundff(:,1:2) = boundf
    do i = 1, NoNests
        print *, "Generating Mesh", i, "/", NoNests
        coord_temp = coord
        call SubGenerateInitialMeshes(NoDim, NoCP, coord_temp, connecf, boundf, coarse, connecc, Coord_CP,Rect, InitialNests(i,:))
        ! Output: New Coordinates - 30 Snapshots with moved boundaries based on initial nests
        
        call IdentifyBoundaryFlags()
        ! Output: Boundary Matrix incluing flags of adiabatic viscous wall, far field & engine inlet (boundff)
        
!!!!! IMPLEMENT Mesh Quality Test

        ! Determine correct String      
        call DetermineStrLen(istr, i) 
        ! Write Snapshot to File
        call InitSnapshots(filename, istr, coord_temp, boundff, NoDim)

        deallocate (istr)
    end do
    
    
    ! ****Call 2D Preprocessor and pass on input parameters**** !
    print *, 'Start Preprocessing'
    pathLin_Prepro = '/eng/cvcluster/egevansbj/codes/prepro/2Dprepro_duct'
    pathWin = 'Flite2D\PreProcessing'   
    do i = 1, NoNests
    
        ! Determine correct String      
        call DetermineStrLen(istr, i)  
        
        if (IsLin == 'N') then
            
            ! write Inputfile (for Windows)
            call PreProInpFileWin(filename, istr)

            allocate(character(len=29) :: strPrepro)
            strPrepro = pathWin
            
        else
            
            ! write command (for Linux)
            PreInt = 59 + 3*len(filename) + 3*len(istr) + len(pathLin_Prepro)
            allocate(character(len=PreInt) :: strPrepro)
            strPrepro = '/bin/echo -e "Output_Data/'//filename//istr//'.dat\nf\n1\n0\n0\n' &        ! Assemble system command string
            //filename//istr//'.sol\n" | '//pathLin_Prepro//'/Aggl2d > '//filename//istr//'.outpre'
            
        end if
        print *, 'Preprocessing Snapshot', i
        print *, ' '
        call system(strPrepro)   ! System operating command called to activate fortran       
        deallocate (istr)
        deallocate (strPrepro)
    
    end do
    print *, 'Finished Preprocessing'
    
    
    ! ****Call 2D FLITE Solver and pass on input parameters**** !
    print *, 'Call FLITE 2D Solver'
    pathLin_Solver = '/eng/cvcluster/egnaumann/2DEngInlSim/2DsolverLin'  
        
    do i = 1, NoNests
            
        ! Determine correct String      
        call DetermineStrLen(istr, i)           
! Test if file exists:  [ -f /etc/hosts ] && echo "Found" || echo "Not found"            
        ! Creates the input file including Solver Parameters and a second file including I/O filenames
        call WriteSolverInpFile(filename, istr, engFMF, hMa, NoIter, newdir)
        ! writes the batchfile to execute Solver on Cluster
        call writeBatchFile(filename, istr, pathLin_Solver)

        ! Is AerOpt executed from Linux or Windows?                
        if (IsLin == 'N')   then    ! AerOpt is executed from a Windows machine
                    
            ! Creates Directory file and Submits via putty(psftp)
            call createDirectories(filename, istr, Username, Password, newdir)
            IntSystem = 96 + len(Username) + len(Password)
            allocate(character(len=IntSystem) :: strSystem)
            strSystem = '"C:\Program Files (x86)\WinSCP\PuTTY\psftp" '//UserName//'@encluster.swan.ac.uk -pw '//Password//' -b FileCreateDir.scr'
            call system(strSystem)
                    
            if (runOnCluster == 'Y') then
                call Triggerfile(filename, istr, newdir)    ! Triggerfile for submission
            else
                call TriggerFile2(filename, istr, newdir)   ! Triggerfile for submission
            end if
                    
            ! Submits Batchfile via Putty
            call system('"C:\Program Files (x86)\WinSCP\PuTTY\putty" -ssh ', UserName, '@encluster.swan.ac.uk -pw ', Password, ' -m Trigger.sh')
                
        else    ! AerOpt is executed from a Linux machine
                    
            call createDirectories2(filename, istr, Username, Password, newdir)
            call system('FileCreateDir.scr')    ! Submits create directory file
                    
            if (runOnCluster == 'Y') then
                call Triggerfile(filename, istr, newdir)    ! Triggerfile for submission
            else
                call TriggerFile2(filename, istr, newdir)   ! Triggerfile for submission
            end if
                    
            ! Submits Batchfile
            call system('Trigger.sh')           ! Submits Batchfile
                    
        end if
                
        deallocate(istr) 
                
    end do
    print *, 'Finished Submitting Jobs to FLITE 2D Solver'         
    
    ! ****Optimize Mesh by the help of Cuckoo Search and POD**** !
    print *, 'Start Optmization'
    call SubOptimization(NoNests, NoCP, NoDim, cond, InitialNests, MxDisp_Move, np, xmax, hMa, p, Aconst, NoPOMod, NoLeviSteps, NoG, constrain)
    ! Output: Optimized mesh via Cuckoo Search and POD
    
    coord_temp = coord
    call SubGenerateInitialMeshes(NoDim, NoCP, coord_temp, connecf, boundf, coarse, connecc, Coord_CP, Rect, NestOpt)
    ! Output: Optimum Coordinates - 1 Mesh with moved boundaries based on optimum Control Point Coordinates
     
    ! Safe Optimum Geometry in Text File
    open(99, file='Output_Data/OptimumMesh.txt')         
    write(99,'(1I8)') np
    write(99,'(1I8)') ne
    write(99,'(2f12.7)') transpose(coord_temp)
11  format(3I8)
    close(99)
    
end program AerOpt