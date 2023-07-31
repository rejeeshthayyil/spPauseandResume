









-- Declare a variable to hold the user-defined table type
DECLARE @inputData ETL.udtfactshootstate;

-- Insert data from the dummy table into the user-defined table variable
INSERT INTO @inputData
SELECT * FROM Report.FactShootStatetbd 

-- Execute the stored procedure to insert the data into the factshootstate table
EXEC spInsertFactShootState   @Factshootstate = @inputData;
