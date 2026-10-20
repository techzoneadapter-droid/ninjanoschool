package huydat.io;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.Statement;

public class SQLManager {
    protected static Connection conn;
    public static Statement stat;

    public static synchronized void create(String host, int port, String database, String user, String pass) {
        try {
            Class.forName("org.mariadb.jdbc.Driver");
        }
        catch (ClassNotFoundException e2) {
            throw new IllegalStateException("MySQL JDBC driver not found", e2);
        }
        String url = "jdbc:mariadb://" + host +":"+port+"/" + database ;
        System.out.println("Kết Nối MySQL : " + url);
        try {
            SQLManager.conn = DriverManager.getConnection(url, user, pass);
            SQLManager.stat = SQLManager.conn.createStatement();
            System.out.println("Kết nối thành công!");
        }
        catch (SQLException e) {
            throw new IllegalStateException("Unable to connect to NSO database at " + host + ":" + port + "/" + database, e);
        }
    }

    public static synchronized boolean close() {
        System.out.println("Đóng kết nối với cơ sở dữ liệu");
        try {
            if (SQLManager.stat != null) {
                SQLManager.stat.close();
            }
            if (SQLManager.conn != null) {
                SQLManager.conn.close();
            }
            return true;
        }
        catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}
