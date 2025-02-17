! SELF_SupportRoutines.f90
!
! Copyright 2020 Fluid Numerics LLC
! Author : Joseph Schoonover (joe@fluidnumerics.com)
! Support : self@higherordermethods.org
!
! //////////////////////////////////////////////////////////////////////////////////////////////// !

!> \file SELF_SupportRoutines.f90
!! Contains the \ref SELF_SupportRoutines module

!> \defgroup SELF_SupportRoutines SELF_SupportRoutines
!! This module defines a set of general purpose routines.

MODULE SELF_SupportRoutines

  USE ISO_FORTRAN_ENV
  USE SELF_Constants

  IMPLICIT NONE

  INTERFACE AlmostEqual
    MODULE PROCEDURE AlmostEqual_r64, &
                     AlmostEqual_r32
  END INTERFACE AlmostEqual
  REAL(prec),PRIVATE,PARAMETER :: tolerance = 10.0**(-10)

CONTAINS

  FUNCTION Int2Str(aNumber) RESULT(aString)
    IMPLICIT NONE
    INTEGER :: aNumber
    CHARACTER(12) :: aString

    WRITE (aString,'(I9)') aNumber

  END FUNCTION Int2Str
  FUNCTION Float2Str(aNumber) RESULT(aString)
    IMPLICIT NONE
    REAL(prec) :: aNumber
    CHARACTER(12) :: aString

    WRITE (aString,'(E12.4)') aNumber

  END FUNCTION Float2Str

!> \addtogroup SELF_SupportRoutines
!! @{
! ================================================================================================ !
! Function AlmostEqual
!
!> \fn AlmostEqual
!! Compares two floating point numbers and determines if they are equal (to machine precision).
!!
!!   This function is from Alg. 139 on pg. 359 of D.A. Kopriva, 2009, "Implementing Spectral Element
!!    Methods for Scientists and Engineers"
!!
!! <H2> Usage : </H2>
!! <B>Logical</B> :: AisB <BR>
!! <B>REAL</B>(prec) :: a, b <BR>
!!         .... <BR>
!!     AisB = AlmostEqual( a, b ) <BR>
!!
!!  <H2> Parameters : </H2>
!!  <table>
!!   <tr> <td> in <th> a <td> REAL(prec) <td> scalar
!!   <tr> <td> in <th> b <td> REAL(prec) <td> scalar
!!   <tr> <td> in <th> AisB <td> Logical <td>
!!                     <B>.TRUE.</B> IF a=b to machine precision <BR>
!!                     <B>.FALSE.</B> otherwise
!!  </table>
!!
! ================================================================================================ !
!>@}

  FUNCTION AlmostEqual_r64(a,b) RESULT(AisB)

    IMPLICIT NONE
    REAL(real64) :: a,b
    LOGICAL :: AisB

    IF (a == 0.0_real64 .OR. b == 0.0_real64) THEN
      IF (ABS(a - b) <= EPSILON(1.0_real64)) THEN
        AisB = .TRUE.
      ELSE
        AisB = .FALSE.
      END IF
    ELSE
      IF ((abs(a - b) <= EPSILON(1.0_real64)*abs(a)) .OR. (abs(a - b) <= EPSILON(1.0_real64)*abs(b))) THEN
        AisB = .TRUE.
      ELSE
        AisB = .FALSE.
      END IF
    END IF

  END FUNCTION AlmostEqual_r64

  FUNCTION AlmostEqual_r32(a,b) RESULT(AisB)

    IMPLICIT NONE
    REAL(real32) :: a,b
    LOGICAL :: AisB

    IF (a == 0.0_real32 .OR. b == 0.0_real32) THEN
      IF (ABS(a - b) <= EPSILON(1.0_real32)) THEN
        AisB = .TRUE.
      ELSE
        AisB = .FALSE.
      END IF
    ELSE
      IF ((abs(a - b) <= EPSILON(1.0_real32)*abs(a)) .OR. (abs(a - b) <= EPSILON(1.0_real32)*abs(b))) THEN
        AisB = .TRUE.
      ELSE
        AisB = .FALSE.
      END IF
    END IF

  END FUNCTION AlmostEqual_r32
!
!> \addtogroup SELF_SupportRoutines
!! @{
! ================================================================================================ !
! S/R InsertionSort
!
!> \fn InsertionSort
!! Sorts an array of integers from smallest to largest using the insertion-sort algorithm.
!!
!! <H2> Usage : </H2>
!! <B>INTEGER</B> :: N <BR>
!! <B>INTEGER</B> :: inArray(1:N) <BR>
!! <B>INTEGER</B> :: outArray(1:N) <BR>
!!         .... <BR>
!!     <B>CALL</B> InsertionSort( inArray, outArray, N ) <BR>
!!
!!  <H2> Parameters : </H2>
!!  <table>
!!   <tr> <td> in <th> N <td> INTEGER <td>
!!                     The number of elements in the input and output arrays
!!   <tr> <td> in <th> inArray(1:N) <td> INTEGER <td>
!!                     Array of unsorted integers.
!!   <tr> <td> out <th> outArray <td> INTEGER <td>
!!                      Array of integers, sorted from most negative to most positive numbers.
!!  </table>
!!
! ================================================================================================ !
!>@}
  SUBROUTINE InsertionSort(inArray,outArray,N)

    IMPLICIT NONE
    INTEGER,INTENT(in)  :: N
    INTEGER,INTENT(in)  :: inArray(1:N)
    INTEGER,INTENT(out) :: outArray(1:N)
    ! LOCAL
    INTEGER :: i,j
    INTEGER :: temp

    outArray = inArray

    DO i = 2,N
      j = i
      DO WHILE (j > 1)
        IF (outArray(j - 1) > outArray(j)) THEN
          !Swap outArray(j) outArray(j-1)
          temp = outArray(j)
          outArray(j) = outArray(j - 1)
          outArray(j - 1) = temp
          j = j - 1
        ELSE
          EXIT
        END IF
      END DO
    END DO

  END SUBROUTINE InsertionSort
!
!> \addtogroup SELF_SupportRoutines
!! @{
! ================================================================================================ !
! S/R SortArray
!
!> \fn SortArray
!! Sorts a REAL(prec) array from smallest absolute value to largest absolute value.
!!
!! <H2> Usage : </H2>
!! <B>REAL</B>(prec) :: myArray(low:high) <BR>
!! <B>INTEGER</B>    :: low, high <BR>
!!         .... <BR>
!!     <B>CALL</B> SortArray( myArray, low, high ) <BR>
!!
!!  <H2> Parameters : </H2>
!!  <table>
!!   <tr> <td> in/out <th> myArray(low:high) <td> REAL(prec) <td>
!!                         On <B>input</B> Unsorted array of floating point values <BR>
!!                         On <B>output</B> Sorted array of floating point values, arranged in order
!!                         of increasing absolute value.
!!   <tr> <td> in <th> low <td> INTEGER <td>
!!                     Lower bound of the input and output arrays
!!   <tr> <td> in <th> high <td> INTEGER <td>
!!                     Upper bound of the input and output arrays
!!  </table>
!!
! ================================================================================================ !
!>@}
  SUBROUTINE SortArray(myArray,low,high)

    IMPLICIT NONE
    INTEGER,INTENT(in)       :: low,high
    REAL(prec),INTENT(inout) :: myArray(low:high)
    ! LOCAL
    INTEGER :: locOfMin
    INTEGER :: ind
    REAL(prec) :: temp

    DO ind = low,high - 1
      locOfMin = MINLOC(abs(myArray(ind:high)),1) + low - 1 + ind
      temp = myArray(ind)
      myArray(ind) = myArray(locOfMin)
      myArray(locOfMin) = temp
    END DO

  END SUBROUTINE SortArray
!
!> \addtogroup SELF_SupportRoutines
!! @{
! ================================================================================================ !
! S/R SortAndSum
!
!> \fn SortAndSum
!! Computes the sum of an array by first sorting the array from smallest absolute value to largest
!! absolute value.
!!
!! When computing the sum of an array of floating point values, round-off errors can be reduced
!! by adding from the smallest to largest values. <BR>
!!
!! This subroutine depends on <BR>
!!    Subroutine \ref sortarray
!!
!! <H2> Usage : </H2>
!! <B>REAL</B>(prec) :: myArray(low:high) <BR>
!! <B>REAL</B>(prec) :: arraySum <BR>
!! <B>INTEGER</B>    :: low, high <BR>
!!         .... <BR>
!!     <B>CALL</B> SortAndSum( myArray, low, high, arraySum ) <BR>
!!
!!  <H2> Parameters : </H2>
!!  <table>
!!   <tr> <td> in/out <th> myArray(low:high) <td> REAL(prec) <td>
!!                         On <B>input</B> Unsorted array of floating point values <BR>
!!                         On <B>output</B> Sorted array of floating point values, arranged in order
!!                         of increasing absolute value.
!!   <tr> <td> in <th> low <td> INTEGER <td>
!!                     Lower bound of the input and output arrays
!!   <tr> <td> in <th> high <td> INTEGER <td>
!!                     Upper bound of the input and output arrays
!!   <tr> <td> out <th> arraySum <td> REAL(prec) <td>
!!                     Sum of the array components.
!!  </table>
!!
! ================================================================================================ !
!>@}
  SUBROUTINE SortAndSum(myArray,low,high,arraysum)

    IMPLICIT NONE
    INTEGER,INTENT(in)       :: low,high
    REAL(prec),INTENT(inout) :: myArray(low:high)
    REAL(prec),INTENT(out)   :: arraysum
    ! LOCAL
    INTEGER :: ind

    CALL SortArray(myArray,low,high)
    arraysum = 0.0_prec
    DO ind = low,high
      arraysum = arraysum + myArray(ind)
    END DO

  END SUBROUTINE SortAndSum
!
!> \addtogroup SELF_SupportRoutines
!! @{
! ================================================================================================ !
! S/R ReverseArray
!
!> \fn ReverseArray
!! Reverses the order of a REAL(prec) array.
!!
!! <H2> Usage : </H2>
!! <B>REAL</B>(prec) :: myArray(low:high) <BR>
!! <B>INTEGER</B>    :: low, high <BR>
!!         .... <BR>
!!     <B>CALL</B> ReverseArray( myArray, low, high ) <BR>
!!
!!  <H2> Parameters : </H2>
!!  <table>
!!   <tr> <td> in/out <th> myArray(low:high) <td> REAL(prec) <td>
!!                         On <B>output</B>, the input array in reverse order .
!!   <tr> <td> in <th> low <td> INTEGER <td>
!!                     Lower bound of the input and output arrays
!!   <tr> <td> in <th> high <td> INTEGER <td>
!!                     Upper bound of the input and output arrays
!!  </table>
!!
! ================================================================================================ !
!>@}

  SUBROUTINE ReverseArray(myArray,low,high)

    IMPLICIT NONE
    INTEGER,INTENT(in)       :: low,high
    REAL(prec),INTENT(inout) :: myArray(low:high)
    ! LOCAL
    REAL(prec) :: temp(low:high)
    INTEGER    :: i,j

    temp = myArray
    j = high
    DO i = low,high
      myArray(i) = temp(j)
      j = j - 1
    END DO

  END SUBROUTINE ReverseArray
!
!> \addtogroup SELF_SupportRoutines
!! @{
! ================================================================================================ !
! S/R ForwardShift
!
!> \fn ForwardShift
!! Shift an array integers by one index forward, moving the last index to the first.
!!
!! Shifts the array entries as follows : <BR>
!!  myArray(1) <-- myArray(N) <BR>
!!  myArray(2) <-- myArray(1) <BR>
!!  myArray(3) <-- myArray(2) <BR>
!!
!! <H2> Usage : </H2>
!! <B>INTEGER</B> :: N
!! <B>INTEGER</B> :: myArray(1:N) <BR>
!!         .... <BR>
!!     <B>CALL</B> ForwardShift( myArray, N ) <BR>
!!
!!  <H2> Parameters : </H2>
!!  <table>
!!   <tr> <td> in/out <th> myArray(1:N) <td> INTEGER <td>
!!                         On <B>output</B>, the input array with elements shifted forward by
!!                         one index.
!!   <tr> <td> in <th> N <td> INTEGER <td>
!!                     The number of elements in the array
!!  </table>
!!
! ================================================================================================ !
!>@}
  SUBROUTINE ForwardShift(myArray,N)

    IMPLICIT NONE
    INTEGER,INTENT(in)    :: N
    INTEGER,INTENT(inout) :: myArray(1:N)
    ! LOCAL
    INTEGER :: temp(1:N)

    temp = myArray
    myArray(1) = temp(N)
    myArray(2:N) = temp(1:N - 1)

  END SUBROUTINE ForwardShift
!
!> \addtogroup SELF_SupportRoutines
!! @{
! ================================================================================================ !
! S/R CompareArray
!
!> \fn CompareArray
!! Compares to INTEGER arrays and determines if they are identical.
!!
!! A logical is returned that specifies whether or not two arrays are identical. To determine
!! if the two arrays are identical, the sum of the difference between each element in the input
!! array is calculated. If the arrays are identical, each contribution to the sum is zero and hence
!! the sum is zero. If the sum is non-zero, the arrays are distinct.
!!
!! This routine is used in the \ref HexMeshClass module. A face of an element in an unstructured
!! mesh is identified by its four corner nodes. When identifying unique faces in an unstructured
!! mesh, we need to determine if two elements share a face. This can be accomplished by comparing
!! the four corner nodes (from each element) that define each face.
!!
!! <H2> Usage : </H2>
!! <B>INTEGER</B> :: N <BR>
!! <B>INTEGER</B> :: arrayOne(1:N) <BR>
!! <B>INTEGER</B> :: arrayTwo(1:N) <BR>
!! <B>LOGICAL</B> :: arraysMatch <BR>
!!         .... <BR>
!!     arraysMatch = CompareArray( arrayOne, arrayTwo, N ) <BR>
!!  <H2> Parameters : </H2>
!!  <table>
!!   <tr> <td> in <th> arrayOne(1:N) <td> INTEGER <td>
!!   <tr> <td> in <th> arrayTwo(1:N) <td> INTEGER <td>
!!   <tr> <td> in <th> N <td> INTEGER <td>
!!   <tr> <td> out <th> arraysMatch <td> INTEGER <td>
!!
!!  </table>
!!
! ================================================================================================ !
!>@}

  FUNCTION CompareArray(arrayOne,arrayTwo,N) RESULT(arraysMatch)

    IMPLICIT NONE
    INTEGER :: N
    INTEGER :: arrayOne(1:N),arrayTwo(1:N)
    LOGICAL :: arraysMatch
    ! LOCAL
    INTEGER :: i,theSumOfDiffs

    theSumOfDiffs = 0

    DO i = 1,N
      theSumOfDiffs = theSumOfDiffs + ABS(arrayOne(i) - arrayTwo(i))
    END DO

    IF (theSumOfDiffs == 0) THEN
      arraysMatch = .TRUE.
    ELSE
      arraysMatch = .FALSE.
    END IF

  END FUNCTION CompareArray
!
!> \addtogroup SELF_SupportRoutines
!! @{
! ================================================================================================ !
! S/R NewUnit
!
!> \fn NewUnit
!! Returns a file unit identifier that is currently not in use.
!!
!!
!! <H2> Usage : </H2>
!! <B>INTEGER</B> :: thisUnit <BR>
!!         .... <BR>
!!     <B>OPEN</B>( UNIT=NewUnit(thisUnit), FILE=filename) <BR>
!!
!!  <H2> Parameters : </H2>
!!  <table>
!!   <tr> <td> out <th> thisunit <td> INTEGER <td> File unit that is not in use
!!  </table>
!!
! ================================================================================================ !
!>@}

  INTEGER FUNCTION NewUnit(thisunit)

    IMPLICIT NONE
    INTEGER,INTENT(out),OPTIONAL :: thisunit
    ! Local
    INTEGER,PARAMETER :: unitMin = 100,unitMax = 1000
    LOGICAL :: isopened
    INTEGER :: iUnit

    newunit = -1

    DO iUnit = unitMin,unitMax
      ! Check to see IF this UNIT is opened
      INQUIRE (UNIT=iUnit,opened=isopened)
      IF (.not. isopened) THEN
        newunit = iUnit
        EXIT
      END IF
    END DO

    IF (PRESENT(thisunit)) thisunit = newunit

  END FUNCTION NewUnit
!
!> \addtogroup SELF_SupportRoutines
!! @{
! ================================================================================================ !
! S/R UniformPoints
!
!> \fn UniformPoints
!! Generates a REAL(prec) array of N points evenly spaced between two points.
!!
!!
!! <H2> Usage : </H2>
!! <B>REAL</B>(prec) :: a <BR>
!! <B>REAL</B>(prec) :: b <BR>
!! <B>REAL</B>(prec) :: xU(0:N) <BR>
!! <B>INTEGER</B> :: N <BR>
!!         .... <BR>
!!     xU = UniformPoints( a, b, N ) <BR>
!!
!!  <H2> Parameters : </H2>
!!  <table>
!!   <tr> <td> in <th> a <td> REAL(prec) <td> Starting point of the interval
!!   <tr> <td> in <th> b <td> REAL(prec) <td> Ending point of the interval
!!   <tr> <td> in <th> N <td> INTEGER <td> The number of points in the interval \f$[a,b]\f$
!!   <tr> <td> in <th> xU(0:N) <td> REAL(prec) <td>
!!                     Array of evenly spaced points in the interval \f$[a,b]\f$
!!  </table>
!!
! ================================================================================================ !
!>@}

  FUNCTION UniformPoints(a,b,firstInd,lastInd) RESULT(xU)

    IMPLICIT NONE
    REAL(prec) :: a,b
    INTEGER    :: firstInd,lastInd
    REAL(prec) :: xU(firstInd:lastInd)
    ! LOCAL
    REAL(prec)    :: dx
    INTEGER :: i

    dx = (b - a)/REAL((lastInd - firstInd),prec)

    DO i = firstInd,lastInd

      xU(i) = a + dx*REAL(i - firstInd,prec)

    END DO

  END FUNCTION UniformPoints
!
!> \addtogroup SELF_SupportRoutines
!! @{
! ================================================================================================ !
! S/R Determinant
!
!> \fn Determinant
!! A recursive function that calculates the determinant of an \f$ N\times N \f$ matrix.
!!
!! This function is used in the functions \ref invert_2x2 and \ref invert_3x3 <BR>
!!
!! This function depends on <BR>
!!    Function \ref getminor
!!
!! <H2> Usage : </H2>
!! <B>INTEGER</B> :: N
!! <B>REAL</B>(prec) :: A(1:N,1:N), D <BR>
!!         .... <BR>
!!     D = Determinant( A, N ) <BR>
!!
!!  <H2> Parameters : </H2>
!!  <table>
!!   <tr> <td> in <th> A(1:N,1:N) <td> REAL(prec) <td> Square matrix
!!   <tr> <td> in <th> N <td> INTEGER <td> Dimension of the matrix
!!   <tr> <td> out <th> detA <td> REAL(prec) <td> The determinant of the matrix
!!  </table>
!!
! ================================================================================================ !
!>@}
  RECURSIVE FUNCTION Determinant(A,N) RESULT(D)

    IMPLICIT NONE
    INTEGER    :: N
    REAL(prec) :: A(1:N,1:N)
    REAL(prec) :: D
    ! LOCAL
    REAL(prec) :: M(1:N - 1,1:N - 1)
    INTEGER    :: j

    IF (N == 2) THEN
      D = A(1,1)*A(2,2) - A(1,2)*A(2,1)
      RETURN
    ELSE
      D = 0.0_prec
      DO j = 1,N
        M = GetMinor(A,1,j,N)
        D = D + (-1.0_prec)**(j + 1)*A(1,j)*Determinant(M,N - 1)
      END DO
    END IF

  END FUNCTION Determinant
!
!> \addtogroup SELF_SupportRoutines
!! @{
! ================================================================================================ !
! Function GetMinor
!
!> \fn GetMinor
!! Returns the submatrix obtained by removing a given row and column of the input matrix.
!!
!! The minor of a matrix is used in calculating the determinant of a matrix.
!!
!! <H2> Usage : </H2>
!! <B>INTEGER</B> :: i, j, N <BR>
!! <B>REAL</B>(prec) :: A(1:N,1:N), M(1:N-1,1:N-1) <BR>
!!         .... <BR>
!!     M = GetMinor( A, i, j, N ) <BR>
!!
!! <H2> Usage : </H2>
!! <B>TYPE</B>(DataType) :: this <BR>
!!         .... <BR>
!!     <B>CALL</B> this % RoutineName( Inputs/Outputs ) <BR>
!!
!!  <H2> Parameters : </H2>
!!  <table>
!!   <tr> <td> in <th> A(1:N,1:N) <td> REAL(prec) <td> Square matrix
!!   <tr> <td> in <th> i <td> INTEGER <td> The row that is removed from A to form the minor of A
!!   <tr> <td> in <th> j <td> INTEGER <td> The column that is removed from A to form the minor of A
!!   <tr> <td> in <th> N <td> INTEGER <td> The dimension of A
!!   <tr> <td> in <th> M(1:N-1,1:N-1) <td> REAL(prec) <td> The (i,j) minor of A
!!  </table>
!!
! ================================================================================================ !
!>@}
  FUNCTION GetMinor(A,i,j,N) RESULT(M)

    IMPLICIT NONE
    INTEGER    :: i,j,N
    REAL(prec) :: A(1:N,1:N)
    REAL(prec) :: M(1:N - 1,1:N - 1)
    ! LOCAL
    INTEGER :: row,col
    INTEGER :: thisRow,thisCol

    thisRow = 0
    DO row = 1,N ! loop over the rows of A
      IF (row /= i) THEN
        thisRow = thisRow + 1
        thisCol = 0
        DO col = 1,N ! loop over the columns of A
          IF (col /= j) THEN
            thisCol = thisCol + 1
            M(thisRow,thisCol) = A(row,col)
          END IF
        END DO ! col, loop over the columns of A
      END IF
    END DO ! row, loop over the rows of A

  END FUNCTION GetMinor
!
!> \addtogroup SELF_SupportRoutines
!! @{
! ================================================================================================ !
! Function Invert_2x2
!
!> \fn Invert_2x2
!!  Computes the inverse of a 2x2 matrix using Kramer's rule.
!!
!! This Function depends on <BR>
!! \ref determinant
!!
!! <H2> Usage : </H2>
!! <B>REAL</B>(prec) :: A(1:2,1:2), Ainv(1:2,1:2) <BR>
!!         .... <BR>
!!     Ainv = Invert_2x2( A ) <BR>
!!
!!  <H2> Parameters : </H2>
!!  <table>
!!   <tr> <td> in <th> A(1:2,1:2) <td> REAL(prec) <td> Real 2x2 matrix
!!   <tr> <td> in <th> Ainv(1:2,1:2) <td> REAL(prec) <td> Real 2x2 matrix, inverse of A
!!  </table>
!!
! ================================================================================================ !
!>@}
  FUNCTION Invert_2x2(A) RESULT(Ainv)

    IMPLICIT NONE
    REAL(prec) :: A(1:2,1:2)
    REAL(prec) :: Ainv(1:2,1:2)
    ! LOCAL
    REAL(prec) :: detA

    detA = Determinant(A,2)

    Ainv(1,1) = A(2,2)/detA
    Ainv(2,2) = A(1,1)/detA
    Ainv(1,2) = -A(1,2)/detA
    Ainv(2,1) = -A(2,1)/detA

  END FUNCTION Invert_2x2
!
!> \addtogroup SELF_SupportRoutines
!! @{
! ================================================================================================ !
! Function Invert_3x3
!
!> \fn Invert_3x3
!!  Computes the inverse of a 3x3 matrix using Kramer's rule.
!!
!! This Function depends on <BR>
!! \ref determinant
!!
!! <H3> Usage : </H3>
!! <B>REAL</B>(prec) :: A(1:3,1:3), Ainv(1:3,1:3) <BR>
!!         .... <BR>
!!     Ainv = Invert_3x3( A ) <BR>
!!
!!  <H3> Parameters : </H3>
!!  <table>
!!   <tr> <td> in <th> A(1:3,1:3) <td> REAL(prec) <td> Real 3x3 matrix
!!   <tr> <td> in <th> Ainv(1:3,1:3) <td> REAL(prec) <td> Real 3x3 matrix, inverse of A
!!  </table>
!!
! ================================================================================================ !
!>@}
  FUNCTION Invert_3x3(A) RESULT(Ainv)
    !
    ! =============================================================================================== !
    IMPLICIT NONE
    REAL(prec) :: A(1:3,1:3)
    REAL(prec) :: Ainv(1:3,1:3)
    ! LOCAL
    REAL(prec) :: detA
    REAL(prec) :: submat(1:2,1:2)
    REAL(prec) :: detSubmat

    detA = Determinant(A,3)

    ! Row 1 column 1 of inverse (use submatrix neglecting row 1 and column 1 of A)
    submat = A(2:3,2:3)
    detSubmat = Determinant(submat,2)
    Ainv(1,1) = detSubmat/detA

    ! Row 1 column 2 of inverse (use submatrix neglecting row 2 and column 1 of A)
    submat = A(1:3:2,2:3)
    detSubmat = Determinant(submat,2)
    Ainv(1,2) = -detSubmat/detA

    ! Row 1 column 3 of inverse (use submatrix neglecting row 3 and column 1 of A)
    submat = A(1:2,2:3)
    detSubmat = Determinant(submat,2)
    Ainv(1,3) = detSubmat/detA

    ! Row 2 column 1 of inverse (use submatrix neglecting row 1 and column 2 of A)
    submat = A(2:3,1:3:2)
    detSubmat = Determinant(submat,2)
    Ainv(2,1) = -detSubmat/detA

    ! Row 2 column 2 of inverse (use submatrix neglecting row 2 and column 2 of A)
    submat = A(1:3:2,1:3:2)
    detSubmat = Determinant(submat,2)
    Ainv(2,2) = detSubmat/detA

    ! Row 2 column 3 of inverse (use submatrix neglecting row 3 and column 2 of A)
    submat = A(1:2,1:3:2)
    detSubmat = Determinant(submat,2)
    Ainv(2,3) = -detSubmat/detA

    ! Row 3 column 1 of inverse (use submatrix neglecting row 1 and column 3 of A)
    submat = A(2:3,1:2)
    detSubmat = Determinant(submat,2)
    Ainv(3,1) = detSubmat/detA

    ! Row 3 column 2 of inverse (use submatrix neglecting row 2 and column 3 of A)
    submat = A(1:3:2,1:2)
    detSubmat = Determinant(submat,2)
    Ainv(3,2) = -detSubmat/detA

    ! Row 3 column 3 of inverse (use submatrix neglecting row 3 and column 3 of A)
    submat = A(1:2,1:2)
    detSubmat = Determinant(submat,2)
    Ainv(3,3) = detSubmat/detA

  END FUNCTION Invert_3x3
!
  FUNCTION InvertSpectralOpMatrix(A,N) RESULT(Ainv)
    ! Inverts an (N+1)x(N+1) matrix using a polynomial representation of the
    ! inverse
    IMPLICIT NONE
    INTEGER :: N
    REAL(prec) :: A(0:N,0:N)
    REAL(prec) :: Ainv(0:N,0:N)
    ! Local
    INTEGER    :: row,col,j,iter
    REAL(prec) :: I(0:N,0:N)
    REAL(prec) :: Ainv_ij,maxChange

    Ainv = 0.0_prec
    I = 0.0_prec
    DO row = 0,N
      Ainv(row,row) = 1.0_prec
      I(row,row) = 1.0_prec
    END DO

    DO iter = 1,maxInverseIters

      maxChange = 0.0_prec
      DO col = 0,N
        DO row = 0,N

          Ainv_ij = 0.0_prec
          DO j = 0,N
            Ainv_ij = Ainv_ij + Ainv(j,col)*(I(row,j) - A(row,j))
          END DO
          maxChange = MAX(ABS(Ainv(row,col) - Ainv_ij),maxChange)
          Ainv(row,col) = Ainv_ij

        END DO
      END DO

      IF (maxChange <= tolerance) THEN
        PRINT *, ' InvertSpectralOpMatrix : Converged in ',iter,' iterations.'
        EXIT
      END IF

    END DO

    IF (maxChange > tolerance) THEN
      PRINT *, 'InvertSpectralOpMatrix : Did not converge.',maxChange
    END IF

  END FUNCTION InvertSpectralOpMatrix
!
  FUNCTION UpperCase(str) RESULT(upper)

    Implicit None
    CHARACTER(*),INTENT(In) :: str
    CHARACTER(LEN(str))      :: Upper

    INTEGER :: ic,i

    CHARACTER(27),PARAMETER :: cap = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ '
    CHARACTER(27),PARAMETER :: low = 'abcdefghijklmnopqrstuvwxyz '

    DO i = 1,LEN(str)
      ic = INDEX(low,str(i:i))
      IF (ic > 0) THEN
        Upper(i:i) = cap(ic:ic)
      ELSE
        Upper(i:i) = str(i:i)
      END IF
    END DO

  END FUNCTION UpperCase
!
  FUNCTION TimeStamp(time,units) RESULT(timeStampString)
    IMPLICIT NONE
    REAL(prec)    :: time
    CHARACTER(1)  :: units
    CHARACTER(13) :: timeStampString
    ! Local
    INTEGER      :: day,minute,hour,second,millisecond
    CHARACTER(4) :: dayStamp
    CHARACTER(2) :: hourStamp,minuteStamp,secondStamp
    CHARACTER(3) :: milliSecondStamp
    REAL(real64) :: time_real64

    time_real64 = REAL(time,real64)
    ! Units in "seconds"
    IF (units(1:1) == 's') THEN

      ! Obtain the day
      day = INT(time_real64/86400.0_real64)
      hour = INT((time_real64 &
                  - 86400.0_real64*day)/3600.0_real64)
      minute = INT((time_real64 &
                    - 3600.0_real64*hour &
                    - 86400.0_real64*day)/60.0_real64)
      second = INT((time_real64 &
                    - 60.0_real64*minute &
                    - 3600.0_real64*hour &
                    - 86400.0_real64*day))
      milliSecond = NINT(((time_real64 &
                           - 60.0_real64*minute &
                           - 3600.0_real64*hour &
                           - 86400.0_real64*day) &
                          - REAL(second,real64))*1000.0_real64)

      IF( milliSecond >= 1000 )THEN
        milliSecond = milliSecond - 1000
        second = second + 1
      ENDIF

      IF( second >= 60 )THEN
        second = second - 60
        minute = minute + 1
      ENDIF

      IF( minute >= 60 )THEN
        minute = minute - 60
        hour = hour + 1
      ENDIF

      IF( hour >= 24 )THEN
        hour = hour - 24
        day = day + 1
      ENDIF

      WRITE (dayStamp,'(I4.4)') day
      WRITE (hourStamp,'(I2.2)') hour
      WRITE (minuteStamp,'(I2.2)') minute
      WRITE (secondStamp,'(I2.2)') second
      WRITE (milliSecondStamp,'(I3.3)') millisecond
      timeStampString = dayStamp//hourStamp//minuteStamp//secondStamp//milliSecondStamp

      ! minutes
    ELSEIF (units(1:1) == 'm') THEN

      ! hours
    ELSEIF (units(1:1) == 'h') THEN

    END IF

  END FUNCTION TimeStamp

  LOGICAL FUNCTION IsInf(a)
    IMPLICIT NONE
    REAL(prec) :: a

    IF (a > HUGE(prec)) THEN
      IsInf = .TRUE.
    ELSE
      IsInf = .FALSE.
    END IF
    RETURN

  END FUNCTION IsInf

  FUNCTION FloorSQRT(x) RESULT(sqrtX)
    INTEGER :: x,sqrtX
    ! Local
    INTEGER :: i,res

    IF (x == 0 .OR. x == 1) THEN

      sqrtX = x

    ELSE

      res = 1
      i = 1
      DO WHILE (res <= x)
        i = i + 1
        res = i*i
      END DO

      sqrtX = i - 1

    END IF

  END FUNCTION FloorSQRT

  FUNCTION FloorCURT(x) RESULT(curtX)
    INTEGER :: x,curtX
    ! Local
    INTEGER :: i,res

    IF (x == 0 .OR. x == 1) THEN

      curtX = x

    ELSE

      res = 1
      i = 1
      DO WHILE (res <= x)
        i = i + 1
        res = i*i*i
      END DO

      curtX = i - 1

    END IF

  END FUNCTION FloorCURT

END MODULE SELF_SupportRoutines
