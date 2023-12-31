https://www.sciencedirect.com/topics/computer-science/cloud-deployment-model#:~:text=NIST%20defines%20four%20cloud%20deployment,has%20control%20over%20that%20infrastructure.
--test


https://chat.openai.com/share/67502daa-534c-48e8-916e-871d42a6e53a





-- Declare a variable to hold the user-defined table type
DECLARE @inputData ETL.udtfactshootstate;

-- Insert data from the dummy table into the user-defined table variable
INSERT INTO @inputData
SELECT * FROM Report.FactShootStatetbd 

-- Execute the stored procedure to insert the data into the factshootstate table
EXEC spInsertFactShootState   @Factshootstate = @inputData;
