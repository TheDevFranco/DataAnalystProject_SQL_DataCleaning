--This project is to clean housing data in SQL

--Selecting all to explore the data
SELECT *
FROM NashvilleProject.dbo.NashvilleHousing

----------------------------------------------

--Standarize Date Format

ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate)

-----------------------------
--Checking if there are NULL property addresses

SELECT PropertyAddress
FROM NashvilleProject.dbo.NashvilleHousing
WHERE PropertyAddress is NULL
--We confirm that there are NULL values. ParcerlID has a many to many relationships.

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM NashvilleProject.dbo.NashvilleHousing A
JOIN NashvilleProject.dbo.NashvilleHousing B
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL
--With this query, we filter out the Parcels that have a property address in some rows, but they have a NULL value in some others; which it shouldn't be the case


UPDATE A
SET PropertyAddress = ISNULL (a.PropertyAddress, b.PropertyAddress)
FROM NashvilleProject.dbo.NashvilleHousing A
JOIN NashvilleProject.dbo.NashvilleHousing B
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL
--This query fix the error from the one above (populates correct address into NULL values)

-----------------------------------------------
--Current PropertyAddress has everything in one cell, so I will split Address into 2 columns: Address and City

--First I query, to see what the correct SUBSTRING will look like
SELECT
SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address
, SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress)) as City
FROM NashvilleProject.dbo.NashvilleHousing

--Creating a new column for split address
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING (PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

--Creating a new column for split city
ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING (PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , LEN(PropertyAddress))

------------------------------------------------

--Splitting Owner Address into 3 columns (Address, City and State)

--Creating query to test correct PARSENAME values
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleProject.dbo.NashvilleHousing

--Adding 3 tables
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3))

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--------------------------------------------------------

--Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2
--With this query, we confirm that there are 52 'Y' Values, 399 'N' values. They will be updated to 'Yes' and 'No' respectively

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

-------------------------------------------------------------------

--Finding and removing duplicates

WITH RowNumCTE AS(
SELECT*,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY
					UniqueID
					) row_num
FROM NashvilleProject.dbo.NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num>1

----------------------------------------
--Delete unused columns

ALTER TABLE NashvilleProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress
--I broke this down into some other columns, so no need to keep

ALTER TABLE NashvilleProject.dbo.NashvilleHousing
DROP COLUMN SaleDate
--I also modified this date format, so no need to keep
