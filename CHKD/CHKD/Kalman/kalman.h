#ifndef _KALMAN_H
#define _KALMAN_H
 
#define DT 0.05f // 100Hz
 
// Q diagonal 3x3 with these elements on diagonal
#define Q1 5.0f
#define Q2 100.0f
#define Q3 0.01f

// R diagonal 2x2 with these elements on diagonal
#define R1 1000.0f
#define R2 1000.0f
 
struct _kalman_data
{
	float x1, x2, x3;
    float p11, p12, p13, p21, p22, p23, p31, p32, p33;
    float q1,q2,q3,r1,r2;
};
 
typedef struct _kalman_data kalman_data;

double Q_angle;
double Q_bias;
double R_measure;
double angle; // The angle calculated by the Kalman filter - part of the 2x1 state vector
double bias; // The gyro bias calculated by the Kalman filter - part of the 2x1 state vector
double rate; // Unbiased rate calculated from the rate and the calculated bias - you have to call getAngle to update the rate

double P[2][2]; // Error covariance matrix - This is a 2x2 matrix
double K[2]; // Kalman gain - This is a 2x1 vector
double y; // Angle difference
double S; // Estimate error

void kalman_innovate(kalman_data *data, float z1, float z2);
void kalman_init(kalman_data *data);
void kalmanInit();
double getAngle(double newAngle, double newRate, double dt);
#endif
