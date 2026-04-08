-- HỆ THỐNG CƠ SỞ DỮ LIỆU QUẢN LÝ BÁN VÉ MÁY BAY
-- Hệ quản trị CSDL: SQL Server (T-SQL)

CREATE DATABASE QuanLyBanVeMayBay;
GO

USE QuanLyBanVeMayBay;
GO

-----------------------------------------------------------
-- PHẦN 1: TẠO CÁC BẢNG (TABLES)
-----------------------------------------------------------

-- ================= MODULE 2: QUẢN LÝ CHUYẾN BAY =================
CREATE TABLE hang_bay (
    ma_hang VARCHAR(10) PRIMARY KEY,
    ten_hang NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE san_bay (
    ma_sb VARCHAR(10) PRIMARY KEY,
    ten_sb NVARCHAR(100) NOT NULL,
    thanh_pho NVARCHAR(50) NOT NULL,
    quoc_gia NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE may_bay (
    ma_mb VARCHAR(10) PRIMARY KEY,
    ma_hang VARCHAR(10) FOREIGN KEY REFERENCES hang_bay(ma_hang),
    ten_mb NVARCHAR(100) NOT NULL,
    tong_so_ghe INT NOT NULL
);
GO

CREATE TABLE chuyen_bay (
    ma_cb VARCHAR(10) PRIMARY KEY,
    ma_mb VARCHAR(10) FOREIGN KEY REFERENCES may_bay(ma_mb),
    san_bay_di VARCHAR(10) FOREIGN KEY REFERENCES san_bay(ma_sb),
    san_bay_den VARCHAR(10) FOREIGN KEY REFERENCES san_bay(ma_sb),
    thoi_gian_di DATETIME NOT NULL,
    thoi_gian_den DATETIME NOT NULL,
    trang_thai NVARCHAR(50) DEFAULT N'Lên lịch',
    CONSTRAINT chk_san_bay CHECK (san_bay_di <> san_bay_den) -- Kiểm tra Sân bay đi <> Sân bay đến
);
GO

-- ================= MODULE 1: QUẢN LÝ NGƯỜI DÙNG =================
CREATE TABLE khach_hang (
    ma_kh VARCHAR(10) PRIMARY KEY,
    ho_ten NVARCHAR(100) NOT NULL,
    email VARCHAR(100),
    sdt VARCHAR(15),
    cmnd_cccd VARCHAR(20) UNIQUE NOT NULL
);
GO

CREATE TABLE nhan_vien (
    ma_nv VARCHAR(10) PRIMARY KEY,
    ho_ten NVARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    sdt VARCHAR(15) UNIQUE,
    chuc_vu NVARCHAR(50) NOT NULL
);
GO

-- ================= MODULE 3: QUẢN LÝ GHẾ & ĐẶT VÉ =================
CREATE TABLE hang_ghe (
    ma_hang_ghe VARCHAR(10) PRIMARY KEY,
    ten_hang_ghe NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE ghe (
    ma_ghe VARCHAR(10) PRIMARY KEY,
    ma_mb VARCHAR(10) FOREIGN KEY REFERENCES may_bay(ma_mb),
    ma_hang_ghe VARCHAR(10) FOREIGN KEY REFERENCES hang_ghe(ma_hang_ghe),
    so_ghe VARCHAR(10) NOT NULL,
    CONSTRAINT uq_ghe_mb UNIQUE(ma_mb, so_ghe) -- Đảm bảo số ghế không trùng lặp trên cùng 1 máy bay
);
GO

-- ================= MODULE 4: THANH TOÁN & DỊCH VỤ =================
CREATE TABLE khuyen_mai (
    ma_km VARCHAR(10) PRIMARY KEY,
    ten_km NVARCHAR(100) NOT NULL,
    phan_tram_giam DECIMAL(5,2) NOT NULL,
    ngay_bat_dau DATE,
    ngay_ket_thuc DATE
);
GO

CREATE TABLE hoa_don (
    ma_hd VARCHAR(10) PRIMARY KEY,
    ma_kh VARCHAR(10) FOREIGN KEY REFERENCES khach_hang(ma_kh),
    ma_km VARCHAR(10) FOREIGN KEY REFERENCES khuyen_mai(ma_km),
    ngay_lap DATETIME DEFAULT GETDATE(),
    tong_tien DECIMAL(18,2) DEFAULT 0
);
GO

CREATE TABLE thanh_toan (
    ma_tt VARCHAR(10) PRIMARY KEY,
    ma_hd VARCHAR(10) FOREIGN KEY REFERENCES hoa_don(ma_hd),
    phuong_thuc NVARCHAR(50) NOT NULL,
    so_tien DECIMAL(18,2) NOT NULL,
    ngay_thanh_toan DATETIME DEFAULT GETDATE(),
    trang_thai NVARCHAR(50) DEFAULT N'Hoàn tất'
);
GO

CREATE TABLE bang_gia (
    ma_cb VARCHAR(10) FOREIGN KEY REFERENCES chuyen_bay(ma_cb),
    ma_hang_ghe VARCHAR(10) FOREIGN KEY REFERENCES hang_ghe(ma_hang_ghe),
    muc_gia DECIMAL(18,2) NOT NULL,
    PRIMARY KEY (ma_cb, ma_hang_ghe)
);
GO

-- Bảng vé phụ thuộc vào hóa đơn, chuyến bay, ghế, khách hàng
CREATE TABLE ve (
    ma_ve VARCHAR(10) PRIMARY KEY,
    ma_kh VARCHAR(10) FOREIGN KEY REFERENCES khach_hang(ma_kh),
    ma_cb VARCHAR(10) FOREIGN KEY REFERENCES chuyen_bay(ma_cb),
    ma_ghe VARCHAR(10) FOREIGN KEY REFERENCES ghe(ma_ghe),
    ma_hd VARCHAR(10) FOREIGN KEY REFERENCES hoa_don(ma_hd),
    ngay_mua DATETIME DEFAULT GETDATE(),
    gia_ve DECIMAL(18,2) NOT NULL,
    trang_thai NVARCHAR(50) DEFAULT N'Đã xuất vé',
    CONSTRAINT uq_chuyenbay_ghe UNIQUE (ma_cb, ma_ghe) -- Đảm bảo 1 ghế / 1 chuyến bay / 1 vé
);
GO

CREATE TABLE dat_cho (
    ma_dat_cho VARCHAR(10) PRIMARY KEY,
    ma_kh VARCHAR(10) FOREIGN KEY REFERENCES khach_hang(ma_kh),
    ma_cb VARCHAR(10) FOREIGN KEY REFERENCES chuyen_bay(ma_cb),
    ma_ghe VARCHAR(10) FOREIGN KEY REFERENCES ghe(ma_ghe),
    thoi_gian_dat DATETIME DEFAULT GETDATE(),
    trang_thai NVARCHAR(50) DEFAULT N'Đang giữ chỗ',
    CONSTRAINT uq_dat_cho_cb_ghe UNIQUE(ma_cb, ma_ghe)
);
GO

CREATE TABLE hanh_ly (
    ma_hl VARCHAR(10) PRIMARY KEY,
    ma_ve VARCHAR(10) FOREIGN KEY REFERENCES ve(ma_ve),
    can_nang DECIMAL(5,2) NOT NULL,
    gia_tien DECIMAL(18,2) NOT NULL
);
GO

-- ================= MODULE 5: BÁO CÁO & HỆ THỐNG =================
CREATE TABLE audit_log (
    ma_log INT IDENTITY(1,1) PRIMARY KEY,
    ten_bang VARCHAR(50),
    hanh_dong VARCHAR(50),
    thoi_gian DATETIME DEFAULT GETDATE(),
    chi_tiet NVARCHAR(MAX)
);
GO


-----------------------------------------------------------
-- PHẦN 2: TRIGGER (RÀNG BUỘC PHỨC TẠP & TỰ ĐỘNG HÓA)
-----------------------------------------------------------

-- 1. Trigger kiểm tra Email/SDT khách hàng không trùng lặp
CREATE TRIGGER trg_CheckEmailPhoneKH
ON khach_hang
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM khach_hang kh
        JOIN inserted i ON (kh.email = i.email OR kh.sdt = i.sdt)
        WHERE kh.ma_kh <> i.ma_kh
    )
    BEGIN
        RAISERROR (N'Email hoặc Số điện thoại đã được sử dụng bởi khách hàng khác!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- 2. Trigger chống đặt trùng ghế (Mặc dù đã có UNIQUE Constraint, nhưng Trigger giúp báo lỗi rõ ràng hơn)
CREATE TRIGGER trg_ChongDatTrungGhe
ON ve
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT v.ma_cb, v.ma_ghe 
        FROM ve v
        GROUP BY v.ma_cb, v.ma_ghe
        HAVING COUNT(*) > 1
    )
    BEGIN
        RAISERROR (N'Lỗi: Ghế này đã được đặt trong chuyến bay!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- 3. Trigger tính toán & cập nhật tổng tiền hóa đơn khi THEO DÕI VÉ
CREATE TRIGGER trg_CapNhatTongTienHD_Ve
ON ve
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @HoaDonIDs TABLE (ma_hd VARCHAR(10));
    INSERT INTO @HoaDonIDs SELECT ma_hd FROM inserted WHERE ma_hd IS NOT NULL;
    INSERT INTO @HoaDonIDs SELECT ma_hd FROM deleted WHERE ma_hd IS NOT NULL;

    -- Tính lại tổng tiền: Giá vé + Giá hành lý - Khuyến mãi
    UPDATE hd
    SET tong_tien = (
        ISNULL((SELECT SUM(v.gia_ve) FROM ve v WHERE v.ma_hd = hd.ma_hd), 0) +
        ISNULL((SELECT SUM(hl.gia_tien) FROM hanh_ly hl JOIN ve v ON hl.ma_ve = v.ma_ve WHERE v.ma_hd = hd.ma_hd), 0)
    )
    FROM hoa_don hd
    WHERE hd.ma_hd IN (SELECT DISTINCT ma_hd FROM @HoaDonIDs);

    -- Áp dụng chiết khấu
    UPDATE hd
    SET tong_tien = tong_tien - (tong_tien * ISNULL(km.phan_tram_giam, 0) / 100)
    FROM hoa_don hd
    LEFT JOIN khuyen_mai km ON hd.ma_km = km.ma_km
    WHERE hd.ma_hd IN (SELECT DISTINCT ma_hd FROM @HoaDonIDs);
END;
GO

-- 4. Trigger tính toán & cập nhật tổng tiền hóa đơn khi THÊM HÀNH LÝ
CREATE TRIGGER trg_CapNhatTongTienHD_HanhLy
ON hanh_ly
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Lấy mã HD bị ảnh hưởng
    DECLARE @HoaDonIDs TABLE (ma_hd VARCHAR(10));
    INSERT INTO @HoaDonIDs 
    SELECT v.ma_hd FROM inserted i JOIN ve v ON i.ma_ve = v.ma_ve
    UNION
    SELECT v.ma_hd FROM deleted d JOIN ve v ON d.ma_ve = v.ma_ve;

    -- Tái tính toán (tương tự như với vé)
    UPDATE hd
    SET tong_tien = (
        ISNULL((SELECT SUM(v.gia_ve) FROM ve v WHERE v.ma_hd = hd.ma_hd), 0) +
        ISNULL((SELECT SUM(hl.gia_tien) FROM hanh_ly hl JOIN ve v ON hl.ma_ve = v.ma_ve WHERE v.ma_hd = hd.ma_hd), 0)
    )
    FROM hoa_don hd
    WHERE hd.ma_hd IN (SELECT DISTINCT ma_hd FROM @HoaDonIDs);

    UPDATE hd
    SET tong_tien = tong_tien - (tong_tien * ISNULL(km.phan_tram_giam, 0) / 100)
    FROM hoa_don hd
    LEFT JOIN khuyen_mai km ON hd.ma_km = km.ma_km
    WHERE hd.ma_hd IN (SELECT DISTINCT ma_hd FROM @HoaDonIDs);
END;
GO

-- 5. Trigger ghi log (Audit) khi thêm vé
CREATE TRIGGER trg_LogThemVe
ON ve
AFTER INSERT
AS
BEGIN
    INSERT INTO audit_log (ten_bang, hanh_dong, chi_tiet)
    SELECT 've', 'INSERT', N'Đã xuất vé ảo số ' + ma_ve + N' cho chuyến bay ' + ma_cb + N' (Ghế: ' + ma_ghe + N')'
    FROM inserted;
END;
GO

-- 6. Trigger ghi log thanh toán
CREATE TRIGGER trg_LogThanhToan
ON thanh_toan
AFTER INSERT
AS
BEGIN
    INSERT INTO audit_log (ten_bang, hanh_dong, chi_tiet)
    SELECT 'thanh_toan', 'INSERT', N'Thanh toán ' + CAST(so_tien AS VARCHAR) + N' cho hóa đơn ' + ma_hd
    FROM inserted;
END;
GO


-----------------------------------------------------------
-- PHẦN 3: STORED PROCEDURES (THỦ TỤC NGHIỆP VỤ)
-----------------------------------------------------------

-- 1. Procedure thêm khách hàng
CREATE PROCEDURE usp_ThemKhachHang
    @ma_kh VARCHAR(10),
    @ho_ten NVARCHAR(100),
    @email VARCHAR(100),
    @sdt VARCHAR(15),
    @cmnd_cccd VARCHAR(20)
AS
BEGIN
    -- Check uniqueness first để trả lời ngay lập tức (hoặc dựa vào Trigger)
    INSERT INTO khach_hang (ma_kh, ho_ten, email, sdt, cmnd_cccd)
    VALUES (@ma_kh, @ho_ten, @email, @sdt, @cmnd_cccd);
END;
GO

-- 2. Procedure tìm chuyến bay theo ngày
CREATE PROCEDURE usp_TimChuyenBayTheoNgay
    @ngay_di DATE
AS
BEGIN
    SELECT 
        cb.ma_cb, 
        mb.ten_mb, 
        sb_di.ten_sb AS SanBayDi, 
        sb_den.ten_sb AS SanBayDen, 
        cb.thoi_gian_di, 
        cb.thoi_gian_den, 
        cb.trang_thai
    FROM chuyen_bay cb
    JOIN may_bay mb ON cb.ma_mb = mb.ma_mb
    JOIN san_bay sb_di ON cb.san_bay_di = sb_di.ma_sb
    JOIN san_bay sb_den ON cb.san_bay_den = sb_den.ma_sb
    WHERE CAST(cb.thoi_gian_di AS DATE) = @ngay_di;
END;
GO

-- 3. Procedure đặt vé an toàn
CREATE PROCEDURE usp_DatVe
    @ma_ve VARCHAR(10),
    @ma_kh VARCHAR(10),
    @ma_cb VARCHAR(10),
    @ma_ghe VARCHAR(10),
    @ma_hd VARCHAR(10),
    @gia_ve DECIMAL(18,2)
AS
BEGIN
    -- Kiểm tra ghế có bị chiếm không
    IF EXISTS (SELECT 1 FROM ve WHERE ma_cb = @ma_cb AND ma_ghe = @ma_ghe)
    BEGIN
        RAISERROR (N'Lỗi: Ghế này đã được đặt!', 16, 1);
        RETURN;
    END

    -- Ensure transaction
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO ve (ma_ve, ma_kh, ma_cb, ma_ghe, ma_hd, gia_ve)
        VALUES (@ma_ve, @ma_kh, @ma_cb, @ma_ghe, @ma_hd, @gia_ve);
        
        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 4. Procedure cập nhật quá trình thanh toán (Thanh toán dựa trên hóa đơn)
CREATE PROCEDURE usp_ThanhToan_HanhDau
    @ma_tt VARCHAR(10),
    @ma_hd VARCHAR(10),
    @phuong_thuc NVARCHAR(50)
AS
BEGIN
    DECLARE @SoTienCanThanhToan DECIMAL(18,2);
    
    -- Lấy số tiền từ hóa đơn
    SELECT @SoTienCanThanhToan = tong_tien FROM hoa_don WHERE ma_hd = @ma_hd;

    IF (@SoTienCanThanhToan IS NULL)
    BEGIN
        RAISERROR(N'Hóa đơn không tồn tại!', 16, 1);
        RETURN;
    END

    INSERT INTO thanh_toan (ma_tt, ma_hd, phuong_thuc, so_tien)
    VALUES (@ma_tt, @ma_hd, @phuong_thuc, @SoTienCanThanhToan);
END;
GO

-----------------------------------------------------------
-- PHẦN 4: FUNCTIONS (HÀM TÍNH TOÁN) & VIEWS (TRUY VẤN)
-----------------------------------------------------------

-- 1. Function tính giá vé dựa vào mã chuyến bay và hãng ghế
CREATE FUNCTION udf_TinhGiaVe 
(
    @ma_cb VARCHAR(10), 
    @ma_hang_ghe VARCHAR(10)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @GiaTien DECIMAL(18,2) = 0;
    
    SELECT @GiaTien = muc_gia 
    FROM bang_gia 
    WHERE ma_cb = @ma_cb AND ma_hang_ghe = @ma_hang_ghe;

    RETURN ISNULL(@GiaTien, 0);
END;
GO

-- 2. View thống kê Doanh Thu Theo Tháng
CREATE VIEW vw_DoanhThuTheoThang AS
SELECT 
    YEAR(ngay_thanh_toan) AS Nam,
    MONTH(ngay_thanh_toan) AS Thang,
    SUM(so_tien) AS TongDoanhThu,
    COUNT(ma_tt) AS SoGiaoDichHoanTat
FROM thanh_toan
GROUP BY 
    YEAR(ngay_thanh_toan), 
    MONTH(ngay_thanh_toan);
GO
