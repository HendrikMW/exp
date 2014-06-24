
!  +++++++++++++++++++++++ BOXTETRA_ROUTINES ++++++++++++++++++++++++++

MODULE BOXTETRA_ROUTINES
USE PRECISION_PARAMETERS
USE MATH_FUNCTIONS, ONLY: CROSS_PRODUCT
IMPLICIT NONE

PRIVATE

INTEGER, DIMENSION(0:3,0:5), TARGET :: BOX_PLANE2VERT
INTEGER, DIMENSION(0:3,0:5), TARGET :: BOX_PLANE2EDGE
INTEGER, DIMENSION(0:1,0:11), TARGET :: BOX_EDGE2VERT

INTEGER, DIMENSION(0:2,0:3), TARGET :: TETRA_PLANE2VERT
INTEGER, DIMENSION(0:2,0:3), TARGET :: TETRA_PLANE2EDGE
INTEGER, DIMENSION(0:1,0:5) :: TETRA_EDGE2VERT

REAL(EB), DIMENSION(0:2,0:5), TARGET :: BOX_NORMALS
REAL(EB), DIMENSION(0:2,0:3), TARGET :: TETRA_NORMALS, TETRA_VERTS
REAL(EB), DIMENSION(0:2,0:7), TARGET :: BOX_VERTS

REAL(EB), DIMENSION(0:5) :: TETRA_BOUNDS
REAL(EB), DIMENSION(0:5,0:3),TARGET :: TETRA_PLANE_BOUNDS
REAL(EB), DIMENSION(0:5,0:5),TARGET :: BOX_PLANE_BOUNDS

INTEGER, PARAMETER :: MIN_X=0, MAX_X=1, MIN_Y=2, MAX_Y=3, MIN_Z=4, MAX_Z=5

INTEGER :: I, J

DATA ( (BOX_NORMALS(I,J), I=0,2),J=0,5) /&
  -1.0_EB,  0.0_EB,  0.0_EB,&
   1.0_EB,  0.0_EB,  0.0_EB,&
   0.0_EB,-1.0_EB,   0.0_EB,&
   0.0_EB,  1.0_EB,  0.0_EB,&
   0.0_EB,  0.0_EB, -1.0_EB,&
   0.0_EB,  0.0_EB,  1.0_EB&
  /

!       6-----------7
!      /.          /| 
!    /  .        /  |
!   4-----------5   |
!   |   .       |   |
!   |   .       |   |
!   |   2.......|...3
!   |  .        |  /
!   | .         | /
!   |.          |/
!   0-----------1

! BOX_PLANE2VERT(edge,plane)
DATA ( (BOX_PLANE2VERT(I,J), I=0,3),J=0,5) /& 
  0,2,4,6,&
  1,3,5,7,&
  0,1,4,5,&
  2,3,6,7,&
  0,1,2,3,&
  4,5,6,7 &
  /
  
!       ------7------
!      /.           / 
!     2 .         3 | 
!    /  .        /  |
!   ------6------   |
!   |  10       |  11
!   |   .       |   |
!   |   .....5..|...|
!   8  .        9  /
!   | 0         | 1
!   |.          |/
!   |----4------|

DATA ( (BOX_PLANE2EDGE(I,J), I=0,3),J=0,5) /&
  0,2,8,10,&
  1,3,9,11,&
  4,6,8,9,&
  5,7,10,11,&
  0,1,4,5,&
  2,3,6,7 &
  /
  
!       6-----7-----7
!      /.           / 
!     2 .         3 | 
!    /  .        /  |
!   4-----6-----5   |
!   |  10       |  11
!   |   .       |   |
!   |   2....5..|...3
!   8  .        9  /
!   | 0         | 1
!   |.          |/
!   0----4------1
! planes: 0-left 1-right 2-front 3-back 4-bottom 5-top
! edges: 0-bottom left  1-bottom right 2-top left   3-top right
!        4-bottom front 5-bottom back  6-top front  7-top back
!        8-front left   9-front right 10-back left 11-back right
! vertices: 0-bottom left front 1-bottom right front 2-bottom left back 3-bottom right back         
!           4-top left front    5-top right front    6-top left back    7-top right back         

 DATA ( (BOX_EDGE2VERT(I,J), I=0,1), J=0,11) /&
  0,2,  1,3,  4,6,  5,7,&
  0,1,  2,3,  4,5,  6,7,&
  0,4,  1,5,  2,6,  3,7&
  /




!           3
!          /.\  
!         / . \
!        /  5  \
!       /   .   \
!      3    2    4
!     /   .   .   \
!    /  2       1  \
!   / .           . \
!  0-------0---------1
  
DATA ( (TETRA_PLANE2VERT(I,J), I=0,2),J=0,3) /&
  0,3,1,&
  1,3,2,&
  0,2,3,&
  0,1,2&
  /
  
DATA ( (TETRA_PLANE2EDGE(I,J), I=0,2),J=0,3) /&
  0,3,4,&
  1,4,5,&
  2,5,3,& !double check (was 2 3 5)
  0,1,2&
  /
  
 DATA ( (TETRA_EDGE2VERT(I,J), I=0,1), J=0,5) /&
  0,1,  1,2,  2,0,&
  0,3,  1,3,  2,3&
  /

PUBLIC GET_TETRABOX_VOLUME, GET_VERTS, VOLUME_VERTS

CONTAINS

!  ------------------ GET_TETRABOX_VOLUME ------------------------ 

REAL(EB) FUNCTION GET_TETRABOX_VOLUME(BOX_BOUNDS,V0,V1,V2,V3)

! compute the volume of the intersection of a box and a tetrahedron

REAL(EB), DIMENSION(0:5), INTENT(IN) :: BOX_BOUNDS
REAL(EB), DIMENSION(0:2), INTENT(IN) :: V0, V1, V2, V3

REAL(EB), DIMENSION(0:599) :: VERTS
INTEGER :: NVERTS, NFACES
INTEGER, DIMENSION(0:199) :: FACESTART, FACENUM
INTEGER :: NORMAL_INDEX(0:9)
INTEGER :: BOX_STATE(-1:5)

! obtain vertices of intersection region

CALL GET_VERTS(BOX_BOUNDS,V0,V1,V2,V3,VERTS,NVERTS,FACESTART,FACENUM,NORMAL_INDEX,NFACES,BOX_STATE)

! compute volume using computed vertices

GET_TETRABOX_VOLUME = GET_POLYHEDRON_VOLUME(VERTS,NVERTS,FACESTART,FACENUM,NFACES)

RETURN
END FUNCTION GET_TETRABOX_VOLUME

!  ------------------ VOLUME_VERTS ------------------------ 

!              D1 
!             /|\  
!            / | \
!           /  |  \  
!          /   |   \  
!         /    |    \ 
!        /     B4    \
!       /     . .     \
!      /     .    .    \   
!     /    .        .   \
!    /   .            .  \    
!   /  .               .  \
!  / .                    .\
! C2------------------------A3

REAL(EB) FUNCTION VOLUME_VERTS(A,B,C,D)

! determine the volume of a tetrahedron formed from vertices A, B, C and D

REAL(EB), DIMENSION(0:2), INTENT(IN) :: A, B, C, D
REAL(EB), DIMENSION(0:2) :: AMC, BMC, DMC, ACROSSB

AMC = A - C
BMC = B - C
DMC = D - C
CALL CROSS_PRODUCT(ACROSSB,AMC, BMC)
VOLUME_VERTS = DOT_PRODUCT(ACROSSB,DMC)/6.0_EB
END FUNCTION VOLUME_VERTS

!  ------------------ GET_POLYHEDRON_VOLUME ------------------------ 

REAL(EB) FUNCTION GET_POLYHEDRON_VOLUME(VERTS,NVERTS,FACESTART,FACENUM,NFACES)

REAL(EB), DIMENSION(0:599), INTENT(IN), TARGET :: VERTS
INTEGER, INTENT(IN) :: NVERTS, NFACES
INTEGER, DIMENSION(0:199), INTENT(IN) :: FACESTART, FACENUM

REAL(EB), DIMENSION(0:2) :: V_CENTER
REAL(EB), DIMENSION(:), POINTER :: V0, V1, V2
REAL(EB) :: VOLUME

! compute center of intersection region

V_CENTER=0.0_EB
DO I = 0, NVERTS - 1
   V_CENTER = V_CENTER + VERTS(3*I:3*I+2)
ENDDO
V_CENTER = V_CENTER/NVERTS

! sum volumes of each region formed using polyhedron face and center

VOLUME=0.0_EB
DO I = 0, NFACES-1
   IF (FACENUM(I)<3) CYCLE
   J = FACESTART(I)
   V0(0:2) => VERTS(3*J:3*J+2)
   DO J = FACESTART(I)+1, FACESTART(I+1)-2
      V1(0:2) => VERTS(3*J:3*J+2)
      V2(0:2) => VERTS(3*J+3:3*J+5)
      VOLUME = VOLUME + ABS(VOLUME_VERTS(V0,V1,V2,V_CENTER))
   ENDDO
ENDDO

GET_POLYHEDRON_VOLUME = VOLUME

END FUNCTION GET_POLYHEDRON_VOLUME

!  ------------------ GET_VERTS ------------------------ 

SUBROUTINE GET_VERTS(BOX_BOUNDS,VV0,VV1,VV2,VV3,VERTS,NVERTS,FACESTART,FACENUM,NORMAL_INDEX,NFACES,BOX_STATE)

! determine vertices of tetrahedron box intersection region ordered by faces

REAL(EB), DIMENSION(0:5), INTENT(IN) :: BOX_BOUNDS
REAL(EB), DIMENSION(0:2), INTENT(IN) :: VV0, VV1, VV2, VV3
REAL(EB), DIMENSION(0:599), INTENT(OUT), TARGET :: VERTS
INTEGER, DIMENSION(0:199), INTENT(OUT) :: FACESTART, FACENUM
INTEGER, DIMENSION(0:9), INTENT(OUT) :: NORMAL_INDEX
INTEGER, INTENT(OUT) :: NVERTS,NFACES
INTEGER, INTENT(OUT) :: BOX_STATE(-1:5)

REAL(EB), DIMENSION(0:2) :: VERT
REAL(EB), POINTER, DIMENSION(:) :: BOXVERT, BOXNORMAL,  BOXVERT0, BOXVERT1
REAL(EB), POINTER, DIMENSION(:) :: TETRAVERT, TETRANORMAL, TETRAVERT0, TETRAVERT1
REAL(EB), POINTER, DIMENSION(:) :: FACEVERTS
INTEGER, POINTER, DIMENSION(:) :: EDGE
REAL(EB), DIMENSION(:), POINTER :: B_PLANE_BOUNDS, T_PLANE_BOUNDS
INTEGER :: TETRA_STATE(0:3)
REAL(EB) :: EPS
REAL(EB) :: VERTS2D(0:299)
INTEGER :: NVERTS2D

INTEGER :: V,E,F,BP,BE,BV,TP,TE,TV

REAL(EB), DIMENSION(0:2) :: V0, V1, V2, V3, VC

REAL(EB), POINTER, DIMENSION(:) :: TET0, TET1, TET2

! setup data structures

V0=VV0
V1=VV1
V2=VV2
V3=VV3
CALL SETUP_VERTS(BOX_BOUNDS,V0,V1,V2,V3)

! swap vertices if orientation is reversed

VC=(V0+V1+V2+V3)/4.0_EB
IF (IN_TETRA(VC,-1).EQ.0) THEN
   V0=VV0
   V1=VV2
   V2=VV1
   V3=VV3
   CALL SETUP_VERTS(BOX_BOUNDS,V0,V1,V2,V3)
ENDIF

NVERTS=0
NFACES=0
FACESTART = 0
FACENUM = 0
NORMAL_INDEX = 0

! return if there is not an intersection

IF (BOX_BOUNDS(1)<TETRA_BOUNDS(0) .OR. BOX_BOUNDS(0)>TETRA_BOUNDS(1)) RETURN
IF (BOX_BOUNDS(3)<TETRA_BOUNDS(2) .OR. BOX_BOUNDS(2)>TETRA_BOUNDS(3)) RETURN
IF (BOX_BOUNDS(5)<TETRA_BOUNDS(4) .OR. BOX_BOUNDS(4)>TETRA_BOUNDS(5)) RETURN

! determine vertices of intersection region

BOX_STATE = -1

EPS = 0.001_EB  ! need to improve this error bound
! TETRA_STATE(I)=J (with J>=0) means that tetra plane I is in the same plane as box plane J
TETRA_STATE(0) = ON_BOX_PLANE(BOX_BOUNDS,V0,V3,V1,EPS)
TETRA_STATE(1) = ON_BOX_PLANE(BOX_BOUNDS,V1,V3,V2,EPS)
TETRA_STATE(2) = ON_BOX_PLANE(BOX_BOUNDS,V0,V2,V3,EPS)
TETRA_STATE(3) = ON_BOX_PLANE(BOX_BOUNDS,V0,V1,V2,EPS)

! BOX_STATE(I)=J (with J>=0) means that box plane I is in the same plane as tetra plane J
BOX_STATE(TETRA_STATE(0))=0
BOX_STATE(TETRA_STATE(1))=1
BOX_STATE(TETRA_STATE(2))=2
BOX_STATE(TETRA_STATE(3))=3

! for each box plane ...

DO BP = 0, 5 
   V = BOX_PLANE2VERT(0,BP) 
   BOXVERT(0:2) => BOX_VERTS(0:2,V)
   BOXNORMAL(0:2) => BOX_NORMALS(0:2,BP)
   B_PLANE_BOUNDS(0:5) => BOX_PLANE_BOUNDS(0:5,BP)
   
   IF (BOX_STATE(BP) /= -1 ) THEN ! this box plane coincides with a tetrhedon plane
                                  ! use a 2D method to find intersections
      TET0(0:2) => TETRA_VERTS(0:2,TETRA_PLANE2VERT(0,BOX_STATE(BP)))
      TET1(0:2) => TETRA_VERTS(0:2,TETRA_PLANE2VERT(1,BOX_STATE(BP)))
      TET2(0:2) => TETRA_VERTS(0:2,TETRA_PLANE2VERT(2,BOX_STATE(BP)))
      CALL GET_VERTS2D(B_PLANE_BOUNDS,BP,TET0,TET2,TET1,VERTS2D,NVERTS2D)
      IF (NVERTS2D>0) THEN
         VERTS(3*NVERTS:3*NVERTS+3*NVERTS2D-1)=VERTS2D(0:3*NVERTS2D-1)
         NVERTS = NVERTS + NVERTS2D
         FACENUM(NFACES) = FACENUM(NFACES) + NVERTS2D
      ENDIF
      IF (FACENUM(NFACES)>0) THEN
         NORMAL_INDEX(NFACES) = BP
         NFACES = NFACES + 1
      ENDIF
      CYCLE
   ENDIF


!  add intersection of tetrahedron edge and box plane (if on box)

   DO TE = 0, 5 ! tetra edge
      TETRAVERT0(0:2) => TETRA_VERTS(0:2,TETRA_EDGE2VERT(0,TE))
      TETRAVERT1(0:2) => TETRA_VERTS(0:2,TETRA_EDGE2VERT(1,TE))
      IF (B_PLANE_BOUNDS(0)>MAX(TETRAVERT0(0),TETRAVERT1(0))) CYCLE
      IF (B_PLANE_BOUNDS(1)<MIN(TETRAVERT0(0),TETRAVERT1(0))) CYCLE
      IF (B_PLANE_BOUNDS(2)>MAX(TETRAVERT0(1),TETRAVERT1(1))) CYCLE
      IF (B_PLANE_BOUNDS(3)<MIN(TETRAVERT0(1),TETRAVERT1(1))) CYCLE
      IF (B_PLANE_BOUNDS(4)>MAX(TETRAVERT0(2),TETRAVERT1(2))) CYCLE
      IF (B_PLANE_BOUNDS(5)<MIN(TETRAVERT0(2),TETRAVERT1(2))) CYCLE
      IF ( BOXPLANE_EDGE_INTERSECTION( BOXVERT,BP,TETRAVERT0,TETRAVERT1,VERT).NE.1) CYCLE
      IF ( IN_BOX(VERT, BP).NE.1) CYCLE

      VERTS(3*NVERTS:3*NVERTS+2)=VERT(0:2)
      FACENUM(NFACES) = FACENUM(NFACES) + 1
      NVERTS=NVERTS+1
   ENDDO

!  add intersection of box plane edge and tetrahedron plane (if on tetrahedron)
  
   EDGE(0:3) => BOX_PLANE2EDGE(0:3,BP)
   DO BE = 0, 3 ! box plane edges
      E = EDGE(BE)
      BOXVERT0(0:2) => BOX_VERTS(0:2,BOX_EDGE2VERT(0,E))
      BOXVERT1(0:2) => BOX_VERTS(0:2,BOX_EDGE2VERT(1,E))
      DO TP = 0, 3 ! tetra plane
         T_PLANE_BOUNDS(0:5) => TETRA_PLANE_BOUNDS(0:5,TP)
         IF (T_PLANE_BOUNDS(0)>MAX(BOXVERT0(0),BOXVERT1(0))) CYCLE
         IF (T_PLANE_BOUNDS(1)<MIN(BOXVERT0(0),BOXVERT1(0))) CYCLE
         IF (T_PLANE_BOUNDS(2)>MAX(BOXVERT0(1),BOXVERT1(1))) CYCLE
         IF (T_PLANE_BOUNDS(3)<MIN(BOXVERT0(1),BOXVERT1(1))) CYCLE
         IF (T_PLANE_BOUNDS(4)>MAX(BOXVERT0(2),BOXVERT1(2))) CYCLE
         IF (T_PLANE_BOUNDS(5)<MIN(BOXVERT0(2),BOXVERT1(2))) CYCLE
         V = TETRA_PLANE2VERT(0,TP)
         TETRAVERT(0:2) => TETRA_VERTS(0:2,V)
         TETRANORMAL(0:2) => TETRA_NORMALS(0:2,TP)
         IF ( PLANE_EDGE_INTERSECTION( TETRAVERT,TETRANORMAL,BOXVERT0,BOXVERT1,VERT).EQ.1) THEN
            IF (IN_TETRA(VERT, TP) .EQ. 1) THEN
               VERTS(3*NVERTS:3*NVERTS+2)=VERT(0:2)
               FACENUM(NFACES) = FACENUM(NFACES) + 1
               NVERTS=NVERTS+1
            ENDIF
         ENDIF
      ENDDO
   ENDDO

! add box plane vertices if inside tetrahedron

   DO BV = 0, 3
      BOXVERT(0:2) => BOX_VERTS(0:2,BOX_PLANE2VERT(BV,BP))
      IF (IN_TETRA(BOXVERT, -1) .EQ. 1) THEN
         VERTS(3*NVERTS:3*NVERTS+2)=BOXVERT(0:2)
         FACENUM(NFACES) = FACENUM(NFACES) + 1
         NVERTS=NVERTS+1
      ENDIF
   ENDDO
   
   IF (FACENUM(NFACES)>0) THEN
      NORMAL_INDEX(NFACES) = BP
      NFACES = NFACES + 1
   ENDIF

ENDDO

! for each tetrahedron plane ....

DO TP = 0, 3
   IF (TETRA_STATE(TP) /= -1 ) CYCLE ! this tetrahedron plane coincides with a tetrhedon plane
                                   ! in this case, use a 2D method to find intersections
   
   V = TETRA_PLANE2VERT(0,TP)
   TETRAVERT(0:2) => TETRA_VERTS(0:2,V)
   TETRANORMAL(0:2) => TETRA_NORMALS(0:2,TP)
   T_PLANE_BOUNDS(0:5) => TETRA_PLANE_BOUNDS(0:5,TP)

!  add intersection of box edge and tetrahedron plane (if on tetrahedron)

   DO BE = 0, 11 ! box edge
      BOXVERT0(0:2) => BOX_VERTS(0:2,BOX_EDGE2VERT(0,BE))
      BOXVERT1(0:2) => BOX_VERTS(0:2,BOX_EDGE2VERT(1,BE))
      IF (T_PLANE_BOUNDS(0)>MAX(BOXVERT0(0),BOXVERT1(0))) CYCLE
      IF (T_PLANE_BOUNDS(1)<MIN(BOXVERT0(0),BOXVERT1(0))) CYCLE
      IF (T_PLANE_BOUNDS(2)>MAX(BOXVERT0(1),BOXVERT1(1))) CYCLE
      IF (T_PLANE_BOUNDS(3)<MIN(BOXVERT0(1),BOXVERT1(1))) CYCLE
      IF (T_PLANE_BOUNDS(4)>MAX(BOXVERT0(2),BOXVERT1(2))) CYCLE
      IF (T_PLANE_BOUNDS(5)<MIN(BOXVERT0(2),BOXVERT1(2))) CYCLE
      IF ( PLANE_EDGE_INTERSECTION( TETRAVERT,TETRANORMAL,BOXVERT0,BOXVERT1,VERT).NE.1) CYCLE
      IF (IN_TETRA(VERT, TP).NE.1) CYCLE

      VERTS(3*NVERTS:3*NVERTS+2)=VERT(0:2)
      FACENUM(NFACES) = FACENUM(NFACES) + 1
      NVERTS=NVERTS+1
   ENDDO

!  add intersection of tetrahedron plane edge and box plane (if on box)
  
   EDGE(0:2) => TETRA_PLANE2EDGE(0:2,TP)
   DO TE = 0, 2 ! tetrahedron plane edges
      E = EDGE(TE)
      TETRAVERT0(0:2) => TETRA_VERTS(0:2,TETRA_EDGE2VERT(0,E))
      TETRAVERT1(0:2) => TETRA_VERTS(0:2,TETRA_EDGE2VERT(1,E))
      DO BP = 0, 5 ! box plane
         B_PLANE_BOUNDS(0:5) => BOX_PLANE_BOUNDS(0:5,BP)
         IF (B_PLANE_BOUNDS(0)>MAX(TETRAVERT0(0),TETRAVERT1(0))) CYCLE
         IF (B_PLANE_BOUNDS(1)<MIN(TETRAVERT0(0),TETRAVERT1(0))) CYCLE
         IF (B_PLANE_BOUNDS(2)>MAX(TETRAVERT0(1),TETRAVERT1(1))) CYCLE
         IF (B_PLANE_BOUNDS(3)<MIN(TETRAVERT0(1),TETRAVERT1(1))) CYCLE
         IF (B_PLANE_BOUNDS(4)>MAX(TETRAVERT0(2),TETRAVERT1(2))) CYCLE
         IF (B_PLANE_BOUNDS(5)<MIN(TETRAVERT0(2),TETRAVERT1(2))) CYCLE
         V = BOX_PLANE2VERT(0,BP)
         BOXVERT(0:2) => BOX_VERTS(0:2,V)
         BOXNORMAL(0:2) => BOX_NORMALS(0:2,BP)
         IF ( BOXPLANE_EDGE_INTERSECTION( BOXVERT,BP,TETRAVERT0,TETRAVERT1,VERT).NE.1) CYCLE
         IF (IN_BOX(VERT, BP) .NE. 1) CYCLE

         VERTS(3*NVERTS:3*NVERTS+2)=VERT(0:2)
         FACENUM(NFACES) = FACENUM(NFACES) + 1
         NVERTS=NVERTS+1
      ENDDO
   ENDDO

! add tetrahedron plane vertices if inside box

   DO TV = 0, 2
      TETRAVERT(0:2) => TETRA_VERTS(0:2,TETRA_PLANE2VERT(TV,TP))
      IF (IN_BOX(TETRAVERT, -1) .EQ. 1) THEN
         VERTS(3*NVERTS:3*NVERTS+2)=TETRAVERT(0:2)
         FACENUM(NFACES) = FACENUM(NFACES) + 1
         NVERTS=NVERTS+1
      ENDIF
   ENDDO
   
   IF (FACENUM(NFACES)>0) THEN
      NORMAL_INDEX(NFACES) = 6+TP
      NFACES = NFACES + 1
   ENDIF

ENDDO

! determine vertex index at the start of each face

DO F = 1, NFACES
  FACESTART(F) = FACESTART(F-1) + FACENUM(F-1)
ENDDO

! order vertices of each face clockwise

DO F = 0, NFACES-1
  IF (FACENUM(F)<=3) CYCLE
  FACEVERTS(0:3*FACENUM(F)-1) => VERTS(3*FACESTART(F):3*FACESTART(F+1)-1)
  CALL ORDER_VERTS(FACEVERTS,FACENUM(F),NORMAL_INDEX(F))
ENDDO

RETURN
END SUBROUTINE GET_VERTS

!  ------------------ GET_VERTS2D ------------------------ 

SUBROUTINE GET_VERTS2D(XB,PLANE_INDEX,VV0,VV1,VV2,VERTS,NVERTS)
! find vertices formed by the intersection of a rectangle and a triangle.  
! The rectangle and triangle lie in the same plane.  The rectangle sides 
! are aligned with the coordinate axes
!                        2   
!                       . .
!                     .   .
!   2---------------.--3  .
!   |              .   |   .
!   |             0    |   .
!   |                . |   .
!   |                  | .  .
!   |                  |    1
!   0------------------1

REAL(EB), DIMENSION(0:5), INTENT(IN) :: XB ! xmin, xmax, ymin, ymax, zmin, zmax
INTEGER, INTENT(IN) :: PLANE_INDEX         ! 0, 1, or 2
REAL(EB), DIMENSION(0:2), INTENT(IN) :: VV0, VV1, VV2
REAL(EB), INTENT(OUT), TARGET :: VERTS(0:299)
INTEGER, INTENT(OUT) :: NVERTS

REAL(EB), DIMENSION(0:4) :: RECT
REAL(EB), TARGET :: TRI_VERTS(0:5), RECT_VERTS(0:7)
REAL(EB), POINTER, DIMENSION(:) :: V0, V1, V2
INTEGER, TARGET :: TRI_EDGES(0:5)=(/0,1, 1,2,  2,0/)
INTEGER, TARGET :: RECT_EDGES(0:7)=(/0,1, 1,3, 3,2, 2,0 /)
INTEGER, POINTER, DIMENSION(:) :: RE, TE

REAL(EB) :: PLANE_VAL
INTEGER :: I, J
REAL(EB), DIMENSION(0:199), TARGET :: VERTS2D
REAL(EB), POINTER, DIMENSION(:) :: V, V2D
REAL(EB), POINTER, DIMENSION(:) :: VIN, VOUT
REAL(EB), POINTER, DIMENSION(:) :: R0, R1, T0, T1
REAL(EB), TARGET :: VERT_SEGS(0:3)
INTEGER :: NVERT_SEGS

NVERTS=0
PLANE_VAL = XB(PLANE_INDEX)
IF (PLANE_INDEX==0) THEN
  TRI_VERTS(0:1) = VV0(1:2)
  TRI_VERTS(2:3) = VV1(1:2)
  TRI_VERTS(4:5) = VV2(1:2)
  RECT(0:3) = XB(2:5)
ELSE IF (PLANE_INDEX==1) THEN
  TRI_VERTS(0:1) = VV0(1:2)
  TRI_VERTS(2:3) = VV1(1:2)
  TRI_VERTS(4:5) = VV2(1:2)
  RECT(0:3) = XB(2:5)
ELSE IF (PLANE_INDEX==2) THEN
  TRI_VERTS(0:1) = (/VV0(0),VV0(2)/)
  TRI_VERTS(2:3) = (/VV1(0),VV1(2)/)
  TRI_VERTS(4:5) = (/VV2(0),VV2(2)/)
  RECT(0:3) = (/XB(0:1),XB(4:5)/)
ELSE IF (PLANE_INDEX==3) THEN
  TRI_VERTS(0:1) = (/VV0(0),VV0(2)/)
  TRI_VERTS(2:3) = (/VV1(0),VV1(2)/)
  TRI_VERTS(4:5) = (/VV2(0),VV2(2)/)
  RECT(0:3) = (/XB(0:1),XB(4:5)/)
ELSE IF (PLANE_INDEX==4) THEN
  TRI_VERTS(0:1) = VV0(0:1)
  TRI_VERTS(2:3) = VV1(0:1)
  TRI_VERTS(4:5) = VV2(0:1)
  RECT(0:3) = XB(0:3)
ELSE
  TRI_VERTS(0:1) = VV0(0:1)
  TRI_VERTS(2:3) = VV1(0:1)
  TRI_VERTS(4:5) = VV2(0:1)
  RECT(0:3) = XB(0:3)
ENDIF
RECT_VERTS(0:1)=(/RECT(0),RECT(2)/)
RECT_VERTS(2:3)=(/RECT(1),RECT(2)/)
RECT_VERTS(4:5)=(/RECT(0),RECT(3)/)
RECT_VERTS(6:7)=(/RECT(1),RECT(3)/)
V0(0:1)=>TRI_VERTS(0:1)
V1(0:1)=>TRI_VERTS(2:3)
V2(0:1)=>TRI_VERTS(4:5)

! check for triangle verts inside rectangles

DO I = 0, 2
   VIN(0:1)=>TRI_VERTS(2*I:2*I+1)
   IF (IN_RECTANGLE2D(RECT,VIN)) THEN
      VOUT(0:1)=>VERTS2D(2*NVERTS:2*NVERTS+1)
      VOUT(0:1) = VIN(0:1)
      NVERTS = NVERTS + 1
   ENDIF
ENDDO

! check for rectangle verts inside triangles

DO I = 0, 3
   VIN(0:1)=>RECT_VERTS(2*I:2*I+1)
   IF (IN_TRIANGLE2D(V0,V1,V2,VIN)) THEN
      VOUT(0:1)=>VERTS2D(2*NVERTS:2*NVERTS+1)
      VOUT(0:1) = VIN(0:1)
      NVERTS = NVERTS + 1
   ENDIF
ENDDO

! check for rectangle edges that intersect with triangle edges

DO I = 0, 3 ! rectangle edges
   RE(0:1)=>RECT_EDGES(2*I:2*I+1)
   R0(0:1)=>RECT_VERTS(2*RE(0):2*RE(0)+1)
   R1(0:1)=>RECT_VERTS(2*RE(1):2*RE(1)+1)
   DO J = 0, 2 ! triangle edges
      TE(0:1)=>TRI_EDGES(2*J:2*J+1)
      T0(0:1)=>TRI_VERTS(2*TE(0):2*TE(0)+1)
      T1(0:1)=>TRI_VERTS(2*TE(1):2*TE(1)+1)
      IF (LINE_SEGMENT_INTERSECT(R0,R1,T0,T1,VERT_SEGS,NVERT_SEGS)) THEN
         VIN(0:1)=>VERT_SEGS(0:1)
         VOUT(0:1)=>VERTS2D(2*NVERTS:2*NVERTS+1)
         VOUT(0:1)=VIN(0:1)
         NVERTS=NVERTS+1
         
         IF (NVERT_SEGS>1) THEN
            VIN(0:1)=>VERT_SEGS(2:3)
            VOUT(0:1)=>VERTS2D(2*NVERTS:2*NVERTS+1)
            VOUT(0:1)=VIN(0:1)
            NVERTS=NVERTS+1
         ENDIF
      ENDIF
   ENDDO
ENDDO

! copy 2d vertex info to 3d vertex array

DO I = 0, NVERTS-1
   V(0:2)=>VERTS(3*I:3*I+2)
   V2D(0:1)=>VERTS2D(2*I:2*I+1)
   IF (PLANE_INDEX==0 .OR. PLANE_INDEX==1) THEN
      V(0:2)=(/PLANE_VAL,V2D(0:1)/)
   ELSE IF (PLANE_INDEX==2 .OR. PLANE_INDEX==3) THEN
      V(0:2)=(/V2D(0),PLANE_VAL,V2D(1)/)
   ELSE
      V(0:2)=(/V2D(0:1),PLANE_VAL/)
   ENDIF
ENDDO

END SUBROUTINE GET_VERTS2D

!  ------------------ IN_RECTANGLE2D ------------------------ 

LOGICAL FUNCTION LINE_SEGMENT_INTERSECT(R0,R1,T0,T1,VERT_SEGS,NVERT_SEGS)
REAL(EB), INTENT(IN), DIMENSION(0:1) :: R0, R1, T0, T1
REAL(EB), INTENT(OUT) :: VERT_SEGS(0:3)
INTEGER, INTENT(OUT) :: NVERT_SEGS
REAL(EB) :: A(2,2), B(2), U(2), DENOM
REAL(EB), PARAMETER :: EPS=0.0001_EB
REAL(EB) :: RXMIN, RXMAX, RYMIN, RYMAX
REAL(EB) :: TXMIN, TXMAX, TYMIN, TYMAX
REAL(EB) :: VERT_SEG_CHECK(0:1)

NVERT_SEGS=0
LINE_SEGMENT_INTERSECT = .FALSE.

! handle case when segments coincide vertically
! (there are two solutions in this case)

IF (ABS(T0(0)-T1(0))<EPS .AND. ABS(R0(0)-R1(0))<EPS) THEN
   TYMIN = MIN(T0(1),T1(1))
   TYMAX = MIN(T0(1),T1(1))
   RYMIN = MIN(R0(1),R1(1))
   RYMAX = MIN(R0(1),R1(1))
   IF (MIN(TYMAX,RYMAX)>MAX(TYMIN,RYMIN)) THEN
      VERT_SEGS(0)=T0(0)
      VERT_SEGS(1)=MIN(TYMAX,RYMAX)
      
      VERT_SEGS(2)=T0(0)
      VERT_SEGS(3)=MAX(TYMIN,RYMIN)
      LINE_SEGMENT_INTERSECT = .TRUE.
      NVERT_SEGS=2
   ENDIF
   RETURN
ENDIF

! handle case when segments coincide horizontally
! (there are two solutions in this case)

IF (ABS(T0(1)-T1(1))<EPS .AND. ABS(R0(1)-R1(1))<EPS) THEN
   TXMIN = MIN(T0(0),T1(0))
   TXMAX = MIN(T0(0),T1(0))
   RXMIN = MIN(R0(0),R1(0))
   RXMAX = MIN(R0(0),R1(0))
   IF (MIN(TXMAX,RXMAX)>MAX(TXMIN,RXMIN)) THEN
      VERT_SEGS(0)=MIN(TXMAX,RXMAX)
      VERT_SEGS(1)=T0(1)
      
      VERT_SEGS(2)=MAX(TXMIN,RXMIN)
      VERT_SEGS(3)=T0(1)
      LINE_SEGMENT_INTERSECT = .TRUE.
      NVERT_SEGS=2
   ENDIF
   RETURN
ENDIF

! find where two lines cross by solving a 2x2 system of linear equations
! the intersection occurs within the two line segments if and only if
! the solution U(1), U(2) lies between 0 and 1

A(1,1) = R1(0)-R0(0)
A(1,2) = -(T1(0)-T0(0))
A(2,1) = R1(1)-R0(1)!
A(2,2) = -(T1(1)-T0(1))

B(1) = (T0(0)-R0(0))
B(2) = (T0(1)-R0(1))

DENOM = A(1,1)*A(2,2)-A(1,2)*A(2,1)
IF (ABS(DENOM)<EPS) RETURN
U(1)=(B(1)*A(2,2)-B(2)*A(1,2))/DENOM
U(2)=(A(1,1)*B(2)-A(2,1)*B(1))/DENOM

! only consider solution when 0<=U<=1

IF (U(1)<0.0_EB .OR. U(1)>1.0_EB .OR. U(2)<0.0_EB .OR. U(2)>1.0_EB) RETURN

VERT_SEGS(0)=R0(0)+(R1(0)-R0(0))*U(1)
VERT_SEGS(1)=R0(1)+(R1(1)-R0(1))*U(1)
NVERT_SEGS=1
LINE_SEGMENT_INTERSECT = .TRUE.
END FUNCTION LINE_SEGMENT_INTERSECT

!  ------------------ IN_RECTANGLE2D ------------------------ 

LOGICAL FUNCTION IN_RECTANGLE2D(XB,VERT)
! tests whether VERT is inside 2d rectangle defined by XB
REAL(EB), INTENT(IN) :: XB(0:3)
REAL(EB), INTENT(IN) :: VERT(0:1)

IF (VERT(0)<XB(0) .OR. VERT(0)>XB(1).OR.&
   VERT(1)<XB(2) .OR. VERT(1)>XB(3)) THEN
   IN_RECTANGLE2D=.FALSE.
ELSE
   IN_RECTANGLE2D=.TRUE.
ENDIF

END FUNCTION IN_RECTANGLE2D

!  ------------------ IN_TRIANGLE2D ------------------------ 

LOGICAL FUNCTION IN_TRIANGLE2D(V0,V1,V2,VERT)
REAL(EB), DIMENSION(0:1), INTENT(IN) :: V0, V1, V2, VERT

REAL(EB), DIMENSION(0:1) :: DV, DVERT, N

!        V0
!       / \
!      /   \
!     /     \
!    /       \
!   /         \
!  V1---------V2

IN_TRIANGLE2D=.FALSE.

DV=V1-V0
DVERT=VERT-V0
N(0:1)=(/DV(1),-DV(0)/) 
IF (N(0)*DVERT(0)+N(1)*DVERT(1)>0.0_EB) RETURN

DV=V2-V1
DVERT=VERT-V1
N(0:1)=(/DV(1),-DV(0)/) 
IF (N(0)*DVERT(0)+N(1)*DVERT(1)>0.0_EB) RETURN

DV=V0-V1
DVERT=VERT-V1
N(0:1)=(/DV(1),-DV(0)/) 
IF (N(0)*DVERT(0)+N(1)*DVERT(1)>0.0_EB) RETURN

IN_TRIANGLE2D=.TRUE.
END FUNCTION IN_TRIANGLE2D

!  ------------------ COMPARE_VERTS ------------------------ 

INTEGER FUNCTION COMPARE_VERTS(A,B,C,N)

! determine orientation of vertices A, B, C relative to vector N

REAL(EB), DIMENSION(0:2), INTENT(IN) :: A, B, C, N
REAL(EB), DIMENSION(0:2) :: AMC, BMC, ACROSSB
REAL(EB) :: VAL

AMC = A - C
BMC = B - C
CALL CROSS_PRODUCT(ACROSSB,AMC, BMC)
VAL = DOT_PRODUCT(ACROSSB,N)/6.0_EB
IF (VAL>0.0_EB) THEN
  COMPARE_VERTS = 1
ELSE IF (VAL.EQ.0.0_EB) THEN
  COMPARE_VERTS = 0
ELSE
  COMPARE_VERTS = -1
ENDIF
END FUNCTION COMPARE_VERTS

!  ------------------ ORDER_VERTS ------------------------ 

SUBROUTINE ORDER_VERTS(FACEVERTS,NVERTS,NORMAL_INDEX)

! order vertices of a given face

INTEGER, INTENT(IN) :: NVERTS, NORMAL_INDEX
REAL(EB), DIMENSION(0:3*NVERTS-1), INTENT(INOUT), TARGET :: FACEVERTS

REAL(EB), DIMENSION(:), POINTER :: NORMAL
REAL(EB), DIMENSION(0:2) :: VERT_CENTER
REAL(EB), DIMENSION(:), POINTER :: VERT, VERT1, VERT2
REAL(EB), DIMENSION(0:3*NVERTS-1) :: FACEVERTS_TEMP
INTEGER :: ORIENTATION
INTEGER :: I, II, IIP1, J
INTEGER, DIMENSION(0:100) :: ORDER
INTEGER :: N_CLOCKWISE, N_COUNTER_CLOCKWISE

! first 6 (starting at 0) normal indices are for box faces
! next 4 (6->9) normal indices are for tetrahedron faces

IF (NORMAL_INDEX<=5) THEN
   NORMAL(0:2) => BOX_NORMALS(0:2,NORMAL_INDEX)
ELSE
   NORMAL(0:2) => TETRA_NORMALS(0:2,NORMAL_INDEX-6)
ENDIF

! find center of vertices

VERT_CENTER=0.0_EB
DO I = 0, NVERTS-1
  VERT(0:2) => FACEVERTS(3*I:3*I+2)
  VERT_CENTER = VERT_CENTER + VERT
ENDDO
VERT_CENTER = VERT_CENTER/REAL(NVERTS,EB)

! split vertices into two parts
!    those before and those after vertex 0

N_CLOCKWISE=0
N_COUNTER_CLOCKWISE=0
VERT1(0:2) => FACEVERTS(0:2)
DO I = 1, NVERTS-1
  VERT2(0:2) => FACEVERTS(3*I:3*I+2)
  ORIENTATION=COMPARE_VERTS(VERT1,VERT2,VERT_CENTER,NORMAL)
  IF (ORIENTATION>=1) THEN
    ORDER(NVERTS-1-N_CLOCKWISE) = I
    N_CLOCKWISE = N_CLOCKWISE + 1
  ELSE
    ORDER(N_COUNTER_CLOCKWISE) = I
    N_COUNTER_CLOCKWISE = N_COUNTER_CLOCKWISE + 1
  ENDIF
ENDDO
ORDER(N_COUNTER_CLOCKWISE) = 0

! order vertices that are counter clockwise from vertex 0

IF (N_COUNTER_CLOCKWISE>1) THEN
   DO J = 0, N_COUNTER_CLOCKWISE - 1
   DO I = 0, N_COUNTER_CLOCKWISE - 2
      II = ORDER(I)
      VERT1(0:2) => FACEVERTS(3*II:3*II+2)
      IIP1 = ORDER(I+1)
      VERT2(0:2) => FACEVERTS(3*IIP1:3*IIP1+2)
      ORIENTATION=COMPARE_VERTS(VERT1,VERT2,VERT_CENTER,NORMAL)
      IF (ORIENTATION<1) THEN
         ORDER(I) = IIP1
         ORDER(I+1) = II
      ENDIF
   ENDDO
   ENDDO
ENDIF

! order vertices that are counter clockwise from vertex 0

IF (N_CLOCKWISE>1) THEN
   DO J = 0, N_CLOCKWISE - 1
   DO I = 0, N_CLOCKWISE - 2
      II = ORDER(N_COUNTER_CLOCKWISE+1+I)
      VERT1(0:2) => FACEVERTS(3*II:3*II+2)
      IIP1 = ORDER(N_COUNTER_CLOCKWISE+1+I+1)
      VERT2(0:2) => FACEVERTS(3*IIP1:3*IIP1+2)
      ORIENTATION=COMPARE_VERTS(VERT1,VERT2,VERT_CENTER,NORMAL)
      IF (ORIENTATION<1) THEN
         ORDER(N_COUNTER_CLOCKWISE+1+I) = IIP1
         ORDER(N_COUNTER_CLOCKWISE+1+I+1) = II
      ENDIF
   ENDDO
   ENDDO
ENDIF

! copy ordered vertices into original data structure

FACEVERTS_TEMP(0:3*NVERTS-1) = FACEVERTS(0:3*NVERTS-1)
DO I = 0, NVERTS-1
   FACEVERTS(3*I:3*I+2) = FACEVERTS_TEMP(3*ORDER(I):3*ORDER(I)+2)
ENDDO

END SUBROUTINE ORDER_VERTS

!  ------------------ SETUP_VERTS ------------------------ 

SUBROUTINE SETUP_VERTS(BOX_BOUNDS,V0,V1,V2,V3)
REAL(EB), DIMENSION(0:5), INTENT(IN) :: BOX_BOUNDS
REAL(EB), DIMENSION(0:2), INTENT(IN) :: V0, V1, V2, V3
REAL(EB), DIMENSION(0:2) :: VDIFF1, VDIFF2, VCROSS
INTEGER :: TP, BP
INTEGER, DIMENSION(:), POINTER :: VERTS

! define box vertices given x/y/z min/max values

BOX_VERTS(0,0) = BOX_BOUNDS(MIN_X)
BOX_VERTS(1,0) = BOX_BOUNDS(MIN_Y)
BOX_VERTS(2,0) = BOX_BOUNDS(MIN_Z)

BOX_VERTS(0,1) = BOX_BOUNDS(MAX_X)
BOX_VERTS(1,1) = BOX_BOUNDS(MIN_Y)
BOX_VERTS(2,1) = BOX_BOUNDS(MIN_Z)

BOX_VERTS(0,2) = BOX_BOUNDS(MIN_X)
BOX_VERTS(1,2) = BOX_BOUNDS(MAX_Y)
BOX_VERTS(2,2) = BOX_BOUNDS(MIN_Z)

BOX_VERTS(0,3) = BOX_BOUNDS(MAX_X)
BOX_VERTS(1,3) = BOX_BOUNDS(MAX_Y)
BOX_VERTS(2,3) = BOX_BOUNDS(MIN_Z)

BOX_VERTS(0,4) = BOX_BOUNDS(MIN_X)
BOX_VERTS(1,4) = BOX_BOUNDS(MIN_Y)
BOX_VERTS(2,4) = BOX_BOUNDS(MAX_Z)

BOX_VERTS(0,5) = BOX_BOUNDS(MAX_X)
BOX_VERTS(1,5) = BOX_BOUNDS(MIN_Y)
BOX_VERTS(2,5) = BOX_BOUNDS(MAX_Z)

BOX_VERTS(0,6) = BOX_BOUNDS(MIN_X)
BOX_VERTS(1,6) = BOX_BOUNDS(MAX_Y)
BOX_VERTS(2,6) = BOX_BOUNDS(MAX_Z)

BOX_VERTS(0,7) = BOX_BOUNDS(MAX_X)
BOX_VERTS(1,7) = BOX_BOUNDS(MAX_Y)
BOX_VERTS(2,7) = BOX_BOUNDS(MAX_Z)

TETRA_BOUNDS(0) = MIN(V0(0),V1(0),V2(0),V3(0))
TETRA_BOUNDS(1) = MAX(V0(0),V1(0),V2(0),V3(0))
TETRA_BOUNDS(2) = MIN(V0(1),V1(1),V2(1),V3(1))
TETRA_BOUNDS(3) = MAX(V0(1),V1(1),V2(1),V3(1))
TETRA_BOUNDS(4) = MIN(V0(2),V1(2),V2(2),V3(2))
TETRA_BOUNDS(5) = MAX(V0(2),V1(2),V2(2),V3(2))

DO TP = 0, 3
  VERTS(0:2) => TETRA_PLANE2VERT(0:2,TP)
  TETRA_PLANE_BOUNDS(0,TP) = MIN(TETRA_VERTS(0,VERTS(0)),TETRA_VERTS(0,VERTS(1)),TETRA_VERTS(0,VERTS(2)))
  TETRA_PLANE_BOUNDS(1,TP) = MAX(TETRA_VERTS(0,VERTS(0)),TETRA_VERTS(0,VERTS(1)),TETRA_VERTS(0,VERTS(2)))
  TETRA_PLANE_BOUNDS(2,TP) = MIN(TETRA_VERTS(1,VERTS(0)),TETRA_VERTS(1,VERTS(1)),TETRA_VERTS(1,VERTS(2)))
  TETRA_PLANE_BOUNDS(3,TP) = MAX(TETRA_VERTS(1,VERTS(0)),TETRA_VERTS(1,VERTS(1)),TETRA_VERTS(1,VERTS(2)))
  TETRA_PLANE_BOUNDS(4,TP) = MIN(TETRA_VERTS(2,VERTS(0)),TETRA_VERTS(2,VERTS(1)),TETRA_VERTS(2,VERTS(2)))
  TETRA_PLANE_BOUNDS(5,TP) = MAX(TETRA_VERTS(2,VERTS(0)),TETRA_VERTS(2,VERTS(1)),TETRA_VERTS(2,VERTS(2)))
ENDDO

DO BP = 0, 5
  VERTS(0:3) => BOX_PLANE2VERT(0:3,BP)
  BOX_PLANE_BOUNDS(0,BP) = MIN(BOX_VERTS(0,VERTS(0)),BOX_VERTS(0,VERTS(1)),BOX_VERTS(0,VERTS(2)),BOX_VERTS(0,VERTS(3)))
  BOX_PLANE_BOUNDS(1,BP) = MAX(BOX_VERTS(0,VERTS(0)),BOX_VERTS(0,VERTS(1)),BOX_VERTS(0,VERTS(2)),BOX_VERTS(0,VERTS(3)))
  BOX_PLANE_BOUNDS(2,BP) = MIN(BOX_VERTS(1,VERTS(0)),BOX_VERTS(1,VERTS(1)),BOX_VERTS(1,VERTS(2)),BOX_VERTS(0,VERTS(3)))
  BOX_PLANE_BOUNDS(3,BP) = MAX(BOX_VERTS(1,VERTS(0)),BOX_VERTS(1,VERTS(1)),BOX_VERTS(1,VERTS(2)),BOX_VERTS(0,VERTS(3)))
  BOX_PLANE_BOUNDS(4,BP) = MIN(BOX_VERTS(2,VERTS(0)),BOX_VERTS(2,VERTS(1)),BOX_VERTS(2,VERTS(2)),BOX_VERTS(0,VERTS(3)))
  BOX_PLANE_BOUNDS(5,BP) = MAX(BOX_VERTS(2,VERTS(0)),BOX_VERTS(2,VERTS(1)),BOX_VERTS(2,VERTS(2)),BOX_VERTS(0,VERTS(3)))
ENDDO

! define tetrahedron vertices

TETRA_VERTS(0:2,0) = V0
TETRA_VERTS(0:2,1) = V1
TETRA_VERTS(0:2,2) = V2
TETRA_VERTS(0:2,3) = V3

! compute normals for each tetrahedron face

VDIFF1 = V0 - V3
VDIFF2 = V1 - V3
CALL CROSS_PRODUCT(VCROSS,VDIFF1,VDIFF2)
TETRA_NORMALS(0:2,0)=VEC_NORMALIZE(VCROSS)

VDIFF1 = V1 - V3
VDIFF2 = V2 - V3
CALL CROSS_PRODUCT(VCROSS,VDIFF1,VDIFF2)
TETRA_NORMALS(0:2,1)=VEC_NORMALIZE(VCROSS)

VDIFF1 = V0 - V2
VDIFF2 = V3 - V2
CALL CROSS_PRODUCT(VCROSS,VDIFF1,VDIFF2)
TETRA_NORMALS(0:2,2)=VEC_NORMALIZE(VCROSS)

VDIFF1 = V0 - V1
VDIFF2 = V2 - V1
CALL CROSS_PRODUCT(VCROSS,VDIFF1,VDIFF2)
TETRA_NORMALS(0:2,3)=VEC_NORMALIZE(VCROSS)

RETURN
END SUBROUTINE SETUP_VERTS

!  ------------------ PLANE_EDGE_INTERSECTION ------------------------ 

INTEGER FUNCTION PLANE_EDGE_INTERSECTION(X0,N0,V0,V1,VERT)

! PLANE: (X-X0).DOT.N0 = 0, EDGE: V0->V1

! find T such that ( (1-T)*V0 + T*V1 - X0 ) .DOT. N0 = 0
! if V1-V0 is perpendicular to N0 ie (V1-V0).DOT.N0 = 0 then there is no solution

REAL(EB), DIMENSION(0:2), INTENT(IN) :: X0, N0, V0, V1
REAL(EB), DIMENSION(0:2), INTENT(OUT) :: VERT
REAL(EB), DIMENSION(0:2) :: V1MV0, V0MX0

REAL(EB) :: DENOM, T

PLANE_EDGE_INTERSECTION=0

V1MV0 = V1-V0
V0MX0 = V0-X0
DENOM = DOT_PRODUCT(V1MV0,N0)
IF (DENOM.NE.0) THEN
   T = -DOT_PRODUCT(V0MX0,N0)/DENOM
   IF (T>=0.0_EB.AND.T<=1.0_EB) THEN
      PLANE_EDGE_INTERSECTION=1
      VERT = V0 + T*V1MV0
   ENDIF
ENDIF
RETURN
END FUNCTION PLANE_EDGE_INTERSECTION

!  ------------------ BOXPLANE_EDGE_INTERSECTION ------------------------ 

INTEGER FUNCTION BOXPLANE_EDGE_INTERSECTION(X0,PLANE,V0,V1,VERT)

! PLANE: (X-X0).DOT.N0 = 0, EDGE: V0->V1

! find T such that ( (1-T)*V0 + T*V1 - X0 ) .DOT. N0 = 0
! if V1-V0 is perpendicular to N0 ie (V1-V0).DOT.N0 = 0 then there is no solution

REAL(EB), DIMENSION(0:2), INTENT(IN) :: X0, V0, V1
INTEGER, INTENT(IN) :: PLANE
REAL(EB), DIMENSION(0:2), INTENT(OUT) :: VERT
REAL(EB), DIMENSION(0:2) :: V1MV0, V0MX0

REAL(EB) :: DENOM, T
INTEGER, DIMENSION(0:5) :: PLANE_INDEX

DATA PLANE_INDEX/0,0,1,1,2,2/

BOXPLANE_EDGE_INTERSECTION=0

V1MV0 = V1-V0
V0MX0 = V0-X0
!DENOM = DOT_PRODUCT(V1MV0,N0)
DENOM = V1MV0(PLANE_INDEX(PLANE))
IF (DENOM.NE.0) THEN
!   T = -DOT_PRODUCT(V0MX0,N0)/DENOM
   T = -V0MX0(PLANE_INDEX(PLANE))/DENOM
   IF (T>=0.0_EB.AND.T<=1.0_EB) THEN
      BOXPLANE_EDGE_INTERSECTION=1
      VERT = V0 + T*V1MV0
   ENDIF
ENDIF
RETURN
END FUNCTION BOXPLANE_EDGE_INTERSECTION

!  ------------------ IN_BOX ------------------------ 

INTEGER FUNCTION IN_BOX(XYZ, IGNORE_PLANE)

! determine if a vertex XYZ is inside the box

REAL(EB), INTENT(IN), DIMENSION(0:2) :: XYZ
INTEGER, INTENT(IN) :: IGNORE_PLANE
  
INTEGER BP
REAL(EB), DIMENSION(0:2) :: VECDIFF
REAL(EB), DIMENSION(:), POINTER :: BOXVERT, BOXNORMAL
  
IN_BOX=1
DO BP = 0, 5
   IF (BP.EQ.IGNORE_PLANE) CYCLE
   BOXVERT(0:2) => BOX_VERTS(0:2,BOX_PLANE2VERT(0,BP))
   BOXNORMAL(0:2) => BOX_NORMALS(0:2,BP)
   VECDIFF = XYZ - BOXVERT
   IF (DOT_PRODUCT(BOXNORMAL,VECDIFF)>0.0_EB) THEN
      IN_BOX=0
      RETURN
   ENDIF
ENDDO
END FUNCTION IN_BOX

!  ------------------ IN_TETRA ------------------------ 

INTEGER FUNCTION IN_TETRA(XYZ, IGNORE_PLANE)

! determine if a vertex XYZ is inside the tetrahedron

REAL(EB), INTENT(IN), DIMENSION(0:2) :: XYZ
INTEGER, INTENT(IN) :: IGNORE_PLANE
REAL(EB), DIMENSION(0:2) :: VECDIFF
REAL(EB), DIMENSION(:), POINTER :: TETRAVERT, TETRANORMAL

INTEGER :: TP
  
IN_TETRA=1
DO TP = 0, 3
   IF (TP.EQ.IGNORE_PLANE) CYCLE
   TETRAVERT(0:2) => TETRA_VERTS(0:2,TETRA_PLANE2VERT(0,TP))
   TETRANORMAL(0:2) => TETRA_NORMALS(0:2,TP)
   VECDIFF = XYZ - TETRAVERT
   IF (DOT_PRODUCT(TETRANORMAL,VECDIFF)>0.0_EB) THEN
      IN_TETRA=0
      RETURN
   ENDIF
ENDDO
END FUNCTION IN_TETRA

!  ------------------ VEC_NORMALIZE ------------------------ 

FUNCTION VEC_NORMALIZE(U)

! normalize a vector so |U|=1

REAL(EB), DIMENSION(0:2) :: VEC_NORMALIZE
REAL(EB), DIMENSION(0:2), INTENT(IN) :: U

REAL(EB) :: SUM

SUM = SQRT(DOT_PRODUCT(U,U))
IF (SUM .NE.0.0_EB) THEN
  VEC_NORMALIZE = U/SUM
ELSE
   VEC_NORMALIZE = U
ENDIF

RETURN
END FUNCTION VEC_NORMALIZE

!  ------------------ ON_BOX_PLANE ------------------------ 

INTEGER FUNCTION ON_BOX_PLANE(XB,V1,V2,V3,EPS)
REAL(EB), INTENT(IN) :: XB(6), V1(3), V2(3), V3(3)
REAL(EB), INTENT(IN) :: EPS

! determines whether the plane formed by the vertices V1, V2 and V3 coincide with one
! of the 6 bounding planes of the box defined by XB

IF (ABS(V1(1)-XB(1))<EPS .AND. ABS(V2(1)-XB(1))<EPS .AND. ABS(V3(1)-XB(1))<EPS) THEN
   ON_BOX_PLANE=0
   RETURN
ENDIF
IF (ABS(V1(1)-XB(2))<EPS .AND. ABS(V2(1)-XB(2))<EPS .AND. ABS(V3(1)-XB(2))<EPS) THEN
   ON_BOX_PLANE=1
   RETURN
ENDIF

IF (ABS(V1(2)-XB(3))<EPS .AND. ABS(V2(2)-XB(3))<EPS .AND. ABS(V3(2)-XB(3))<EPS) THEN
   ON_BOX_PLANE=2
   RETURN
ENDIF
IF (ABS(V1(2)-XB(4))<EPS .AND. ABS(V2(2)-XB(4))<EPS .AND. ABS(V3(2)-XB(4))<EPS) THEN
   ON_BOX_PLANE=3
   RETURN
ENDIF

IF (ABS(V1(3)-XB(5))<EPS .AND. ABS(V2(3)-XB(5))<EPS .AND. ABS(V3(3)-XB(5))<EPS) THEN
   ON_BOX_PLANE=4
   RETURN
ENDIF
IF (ABS(V1(3)-XB(6))<EPS .AND. ABS(V2(3)-XB(6))<EPS .AND. ABS(V3(3)-XB(6))<EPS) THEN
   ON_BOX_PLANE=5
   RETURN
ENDIF
ON_BOX_PLANE=-1
END FUNCTION ON_BOX_PLANE

END MODULE BOXTETRA_ROUTINES
